//
//  KeyModel+Persistence.swift
//  Alpha1
//
//  Created by A on 4/3/23.
//


import Foundation
import Accelerate
import CoreData
import CoreML


extension KeyModel {
    /// Relies on constraint on id
    /// Must be called from main thread, as with try await MainActor.run
    func saveWeightsToCoreDataAndMemoryStructures(modelControlIdString: String, modelWeights: ModelWeights, currentMaxMetric: Float32, minLoss: Float32, moc: NSManagedObjectContext, inMemory_KeyModelGlobalControl: inout InMemory_KeyModelGlobalControl) throws {
        
        var modelControl: ModelControl
        let fetchRequest = ModelControl.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", modelControlIdString)
        fetchRequest.fetchLimit = 1
//            fetchRequest.fetchLimit = 1
        let results = try moc.fetch(fetchRequest)
        if results.isEmpty {
            modelControl = ModelControl(context: moc)
            modelControl.id = modelControlIdString
        } else {
            modelControl = results[0]
        }
        
//        let modelControl = ModelControl(context: moc)
//        modelControl.id = modelControlIdString
        
        if let cnnWeights = modelWeights.cnnWeights,
           let cnnBias = modelWeights.cnnBias,
           let fcWeights = modelWeights.fcWeights,
           let fcBias = modelWeights.fcBias {
            
            modelControl.key0 = Data(fromArray: cnnWeights)
            modelControl.key0b = Data(fromArray: cnnBias)
            modelControl.key1 = Data(fromArray: fcWeights)
            modelControl.key1b = Data(fromArray: fcBias)
            
            modelControl.timestampLastModified = Date()
            modelControl.currentMaxMetric = currentMaxMetric
            modelControl.minLoss = minLoss  // Note that this is the min loss associated with the max metric epoch (it may not be the global min loss)
            
            if modelControl.id == REConstants.ModelControl.keyModelId {
                // create a new UUID to uniquely identify this set of weights
                let uniqueIDString = UUID().uuidString
                modelControl.keyModelUUID = uniqueIDString
                // Currently, the corresponding indexModelUUID is always default for the keyModel:
                modelControl.indexModelUUID = REConstants.ModelControl.defaultIndexModelUUID
                // update the in-memory version, as well:
                inMemory_KeyModelGlobalControl.keyModelUUID = uniqueIDString
                
                modelControl.state = InMemory_KeyModelGlobalControl.TrainingState.Trained.rawValue
                modelControl.maxMetric = inMemory_KeyModelGlobalControl.trainingMaxMetric.rawValue
                
                inMemory_KeyModelGlobalControl.modelWeights = modelWeights
                inMemory_KeyModelGlobalControl.trainingState = .Trained
                // no change: inMemory_KeyModelGlobalControl.trainingMaxMetric
                inMemory_KeyModelGlobalControl.trainingCurrentMaxMetric = modelControl.currentMaxMetric
                inMemory_KeyModelGlobalControl.trainingTimestampLastModified = modelControl.timestampLastModified
                inMemory_KeyModelGlobalControl.trainingMinLoss = modelControl.minLoss
            } else if modelControl.id == REConstants.ModelControl.indexModelId {
                // create a new UUID to uniquely identify this set of weights
                let uniqueIDString = UUID().uuidString
                modelControl.indexModelUUID = uniqueIDString
                // We assign the current keyModel id to make the connection between the original model and the compressed version:
                modelControl.keyModelUUID = inMemory_KeyModelGlobalControl.keyModelUUID
                // update the in-memory version, as well:
                inMemory_KeyModelGlobalControl.indexModelUUID = uniqueIDString
                inMemory_KeyModelGlobalControl.keyModelUUIDOwnedByIndexModel = inMemory_KeyModelGlobalControl.keyModelUUID
                
                modelControl.state = InMemory_KeyModelGlobalControl.IndexState.Built.rawValue
                modelControl.maxMetric = inMemory_KeyModelGlobalControl.indexMaxMetric.rawValue
                
                inMemory_KeyModelGlobalControl.indexModelWeights = modelWeights
                inMemory_KeyModelGlobalControl.indexState = .Built
                // no change: inMemory_KeyModelGlobalControl.indexMaxMetric
                inMemory_KeyModelGlobalControl.indexCurrentMaxMetric = modelControl.currentMaxMetric
                inMemory_KeyModelGlobalControl.indexTimestampLastModified = modelControl.timestampLastModified
                inMemory_KeyModelGlobalControl.indexMinLoss = modelControl.minLoss
            }
            do {
                if moc.hasChanges {
                    try moc.save()
                }
            } catch {
                throw CoreDataErrors.saveError
            }
        }
    }
    /// Note that we only retain a finite number of epochs. The best value is always maintained in the data structure.
    func _updateEpochValueTuples(epochValueTuples: inout [(epoch: Int, value: Float32)], newValue: Float32, lowerIsBetter: Bool = false) {

        if epochValueTuples.count < REConstants.KeyModelConstraints.maxSavedEpochs {
            epochValueTuples.append(
                (epoch: epochValueTuples.count, value: newValue)
            )
        } else {  // hard max reached; from here, only add best. This should rarely, if ever, occur, because the max is quite high. This is just to prevent runaway storage.
            let last = epochValueTuples.removeLast()
            if last.value < newValue {
                let newTuple = (epoch: epochValueTuples.count-1, value: lowerIsBetter ? last.value : newValue)
                epochValueTuples.append(newTuple)
            } else {
                let newTuple = (epoch: epochValueTuples.count-1, value: lowerIsBetter ? newValue : last.value)
                epochValueTuples.append(newTuple)
            }
        }
    }
    /// Must be called from main thread, as with try await MainActor.run
    /// Note that we only retain the top 1000 epochs
    func updateTrainingProcessData(modelControlIdString: String,
                                   trainingLoss: Float32,
                                   validationLoss: Float32,
                                   trainingScore: Float32,
                                   validationScore: Float32,
                                   moc: NSManagedObjectContext,
                                   inMemory_KeyModelGlobalControl: inout InMemory_KeyModelGlobalControl) throws {
        
        let trainingProcessIndex = 0 // 0 for training; 1 for validation
        let validationProcessIndex = 1
        if modelControlIdString == REConstants.ModelControl.keyModelId {
            _updateEpochValueTuples(epochValueTuples: &inMemory_KeyModelGlobalControl.trainingProcessDataStorageLoss.trainingProcessData[trainingProcessIndex].epochValueTuples, newValue: trainingLoss, lowerIsBetter: true)
            _updateEpochValueTuples(epochValueTuples: &inMemory_KeyModelGlobalControl.trainingProcessDataStorageLoss.trainingProcessData[validationProcessIndex].epochValueTuples, newValue: validationLoss, lowerIsBetter: true)
            _updateEpochValueTuples(epochValueTuples: &inMemory_KeyModelGlobalControl.trainingProcessDataStorageMetric.trainingProcessData[trainingProcessIndex].epochValueTuples, newValue: trainingScore, lowerIsBetter: false)
            _updateEpochValueTuples(epochValueTuples: &inMemory_KeyModelGlobalControl.trainingProcessDataStorageMetric.trainingProcessData[validationProcessIndex].epochValueTuples, newValue: validationScore, lowerIsBetter: false)
        } else if modelControlIdString == REConstants.ModelControl.indexModelId {
            _updateEpochValueTuples(epochValueTuples: &inMemory_KeyModelGlobalControl.indexProcessDataStorageLoss.trainingProcessData[trainingProcessIndex].epochValueTuples, newValue: trainingLoss, lowerIsBetter: true)
            _updateEpochValueTuples(epochValueTuples: &inMemory_KeyModelGlobalControl.indexProcessDataStorageLoss.trainingProcessData[validationProcessIndex].epochValueTuples, newValue: validationLoss, lowerIsBetter: true)
            _updateEpochValueTuples(epochValueTuples: &inMemory_KeyModelGlobalControl.indexProcessDataStorageMetric.trainingProcessData[trainingProcessIndex].epochValueTuples, newValue: trainingScore, lowerIsBetter: false)
            _updateEpochValueTuples(epochValueTuples: &inMemory_KeyModelGlobalControl.indexProcessDataStorageMetric.trainingProcessData[validationProcessIndex].epochValueTuples, newValue: validationScore, lowerIsBetter: false)
        }
        
        // save to database
        var modelControl: ModelControl
        let fetchRequest = ModelControl.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", modelControlIdString)
        fetchRequest.fetchLimit = 1
//            fetchRequest.fetchLimit = 1
        let results = try moc.fetch(fetchRequest)
        if results.isEmpty {
            modelControl = ModelControl(context: moc)
            modelControl.id = modelControlIdString
        } else {
            modelControl = results[0]
        }
        //var dbNumberOfEvalSets: Int = 1
//        for modelControl in results {
            
//        let modelControl = ModelControl(context: moc)
//        modelControl.id = modelControlIdString
        
        if modelControlIdString == REConstants.ModelControl.keyModelId {
            modelControl.trainingProcessDataTrainLoss = Data(fromArray: inMemory_KeyModelGlobalControl.trainingProcessDataStorageLoss.trainingProcessData[trainingProcessIndex].epochValueTuples.map { $0.value })
            modelControl.trainingProcessDataValidLoss = Data(fromArray: inMemory_KeyModelGlobalControl.trainingProcessDataStorageLoss.trainingProcessData[validationProcessIndex].epochValueTuples.map { $0.value })
            
            modelControl.trainingProcessDataTrainMetric = Data(fromArray: inMemory_KeyModelGlobalControl.trainingProcessDataStorageMetric.trainingProcessData[trainingProcessIndex].epochValueTuples.map { $0.value })
            modelControl.trainingProcessDataValidMetric = Data(fromArray: inMemory_KeyModelGlobalControl.trainingProcessDataStorageMetric.trainingProcessData[validationProcessIndex].epochValueTuples.map { $0.value })
            
        } else if modelControlIdString == REConstants.ModelControl.indexModelId {
            modelControl.trainingProcessDataTrainLoss = Data(fromArray: inMemory_KeyModelGlobalControl.indexProcessDataStorageLoss.trainingProcessData[trainingProcessIndex].epochValueTuples.map { $0.value })
            modelControl.trainingProcessDataValidLoss = Data(fromArray: inMemory_KeyModelGlobalControl.indexProcessDataStorageLoss.trainingProcessData[validationProcessIndex].epochValueTuples.map { $0.value })
            
            modelControl.trainingProcessDataTrainMetric = Data(fromArray: inMemory_KeyModelGlobalControl.indexProcessDataStorageMetric.trainingProcessData[trainingProcessIndex].epochValueTuples.map { $0.value })
            modelControl.trainingProcessDataValidMetric = Data(fromArray: inMemory_KeyModelGlobalControl.indexProcessDataStorageMetric.trainingProcessData[validationProcessIndex].epochValueTuples.map { $0.value })
        }
        
        do {
            if moc.hasChanges {
                try moc.save()
            }
        } catch {
            throw CoreDataErrors.saveError
        }
    }
}
