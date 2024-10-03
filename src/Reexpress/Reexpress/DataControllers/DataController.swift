//
//  DataController.swift
//  Alpha1
//
//  Created by A on 1/28/23.
//

import CoreData
import Foundation
import CoreML


//class InMemory_DatasetGlobalControl: ObservableObject {
//    var id = UUID().uuidString
//    @Published var modelTaskType: ModelTask = .binaryClassification
//    @Published var numberOfClasses: Int = 3
//    @Published var modelGroup: SentencepieceConstants.ModelGroup = .Fastest
//
//    init() {
//        //id = UUID().uuidString
//    }
//
//}

struct InMemory_Dataset {
//    var id: Int64
//    var internalName: String
//    var count: Int64?
    var id: Int
    var internalName: String
    var count: Int?
    var userSpecifiedName: String?
    //var documentIds: Set<String>?
    
//    init() {
//
//    }
    
}

struct InMemory_KeyModelGlobalControl {
    
    enum TrainingState: Int, CaseIterable {
        case Untrained  // never trained, or previously trained but state has been cleared
        case Trained  // trained on the current training set
        case Stale  // training parameters are out of date, as for example, due to a change in the instances or labels in the training set
    }
    enum IndexState: Int, CaseIterable {  // controls the state of the vector database
        case Unbuilt
        case Built
        case Stale
    }
    enum MaxMetric: Int, CaseIterable {  // metric for determining the training epoch; currently always w.r.t. calibration/validation set
        case Accuracy
        case BalancedAccuracy  // Accuracy per class equally weighted by class: e.g., (Acc. class 0 + Acc. class 1) / 2
        case F1
        case F05
        
        case F1Micro
        case F1Macro
        case F05Macro
        case F05Micro
        case AUC
        case NegativeLoss  // saved as negative so highest values preferred for all metrics
        
        var description: String {
          switch self {
          case .Accuracy: return "Accuracy"
          case .BalancedAccuracy: return "Balanced Accuracy"
          case .F1: return "F1"
          case .F05: return "F0.5"
          case .F1Micro: return "F1 Micro"
          case .F1Macro: return "F1 Macro"
          case .F05Macro: return "F.05 Macro"
          case .F05Micro: return "F.05 Micro"
          case .AUC: return "AUC"
          case .NegativeLoss: return "Negative Loss"
          }
        }
    }
    var trainingState: TrainingState = .Untrained
    var trainingMaxMetric: MaxMetric = .BalancedAccuracy
    var trainingCurrentMaxMetric: Float =  -Float.infinity
    var trainingTimestampLastModified: Date?
    var trainingMinLoss: Float = Float.infinity
    
    var indexState: IndexState = .Unbuilt
    var indexMaxMetric: MaxMetric = .BalancedAccuracy
    var indexCurrentMaxMetric: Float =  -Float.infinity
    var indexTimestampLastModified: Date?
    var indexMinLoss: Float = Float.infinity
    
    var modelWeights: KeyModel.ModelWeights?
    var indexModelWeights: KeyModel.ModelWeights?
    
    // These only get updated on saving of the model weights.
    var keyModelUUID: String = REConstants.ModelControl.defaultIndexModelUUID
    // if keyModelUUID != keyModelUUIDOwnedByIndexModel and != REConstants.ModelControl.defaultIndexModelUUID, then the keyModel has been re-trained since the index model and the index model needs to be updated.
    var keyModelUUIDOwnedByIndexModel: String = REConstants.ModelControl.defaultIndexModelUUID
    var indexModelUUID: String = REConstants.ModelControl.defaultIndexModelUUID  // This is the final model trained in the sequence, so this is used to mark Documents (i.e., Document.modelUUID).
    
    func getTrainingStateString(abbreviated: Bool = false) -> String {
        switch trainingState {
        case .Untrained:
            return "Not yet trained"
        case .Trained:
            return "Trained"
        case .Stale:
            if abbreviated {
                return "Retrain needed"
            }
            return "Retrain needed (training set changed)"
        }
    }
    func getIndexStateString(abbreviated: Bool = false) -> String {
        switch indexState {
        case .Unbuilt:
            return "Not yet trained"
        case .Built:
            return "Trained"
        case .Stale:
            if abbreviated {
                return "Retrain needed"
            }
            return "Retrain needed (training set changed)"
        }
    }
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
    // training data for graphs:
    var trainingProcessDataStorageLoss = TrainingProcessDataStorage()
    var trainingProcessDataStorageMetric = TrainingProcessDataStorage()
    
    var indexProcessDataStorageLoss = TrainingProcessDataStorage()
    var indexProcessDataStorageMetric = TrainingProcessDataStorage()
}


//struct InMemory_Document {
//    init() {
//    }
//}
//struct InMemory_Attributes {
//    init() {
//    }
//}
//struct InMemory_Embedding {
//    init() {
//    }
//}


class DataController: ObservableObject {
    
    var projectURL: URL?
    var tokenizer: SentencepieceTokenizer?
    var multiTokenizer: SentencepieceTokenizer?
    
    //private var inMemory_DatasetGlobalControl = InMemory_DatasetGlobalControl()
    
    @Published var id = UUID().uuidString  // Note this is a global UUID for the entire project
    @Published var modelTaskType: ModelTask = .binaryClassification
    @Published var numberOfClasses: Int = 2
    @Published var modelGroup: SentencepieceConstants.ModelGroup = .Fastest
    @Published var numberOfEvalSets: Int = 1
    // In the current version, the defaultPrompt is expected to remain constant for the life of the project, so it is not a published var:
    var defaultPrompt: String = ""
    @Published var labelToName: [Int: String] = [:]
    
//    @Published var inMemory_Datasets: [Int64: InMemory_Dataset] = [:]
    @Published var inMemory_Datasets: [Int: InMemory_Dataset] = [:]
    @Published var inMemory_KeyModelGlobalControl = InMemory_KeyModelGlobalControl()
    @Published var currentInferenceProgress = 0
    
    
    let decoder = JSONDecoder()  // decoder is in the extension
    
    var uncertaintyStatistics: UncertaintyStatistics?
    
    
    @Published var documentSelectionState_DocumentsOverview: DocumentSelectionState? = nil
    var selectedDBRow_DocumentsOverview: DatabaseRetrievalRow? = nil
    @Published var documentSelectionState_CompareGraph: DocumentSelectionState? = nil
    var comparisonDatasetId_CompareGraph: Int? = nil
    // We maintain indicators as to whether the Table or Chart has been shown at least once. On the first appearance, we show an alert indicating the Training Set is selected.
    @Published var documentsOverviewSelectionHasBeenShown: Bool = false
    @Published var compareGraphSelectionHasBeenShown: Bool = false
    /// Get ModelControl properties from the database for an existing project. Should be called from main thread
    func getModelControlPropertiesFromDatabase(moc: NSManagedObjectContext) throws {
     
        //try await MainActor.run {
            let fetchRequest = ModelControl.fetchRequest()
//            fetchRequest.fetchLimit = 1
            let results = try moc.fetch(fetchRequest)
            //var dbNumberOfEvalSets: Int = 1
            for modelControl in results {
                if let cnnWeights = modelControl.key0?.toArray(type: Float32.self), let cnnBias = modelControl.key0b?.toArray(type: Float32.self), let fcWeights = modelControl.key1?.toArray(type: Float32.self), let fcBias = modelControl.key1b?.toArray(type: Float32.self) {
                    if modelControl.id == REConstants.ModelControl.keyModelId {
                        
                        inMemory_KeyModelGlobalControl.keyModelUUID = modelControl.keyModelUUID ?? REConstants.ModelControl.defaultIndexModelUUID
                        
                        inMemory_KeyModelGlobalControl.modelWeights = (cnnWeights: cnnWeights, cnnBias: cnnBias, fcWeights: fcWeights, fcBias: fcBias)
                        inMemory_KeyModelGlobalControl.trainingState = InMemory_KeyModelGlobalControl.TrainingState(rawValue: modelControl.state) ?? .Stale
                        inMemory_KeyModelGlobalControl.trainingMaxMetric = InMemory_KeyModelGlobalControl.MaxMetric(rawValue: modelControl.maxMetric) ?? .BalancedAccuracy
                        inMemory_KeyModelGlobalControl.trainingCurrentMaxMetric = modelControl.currentMaxMetric
                        inMemory_KeyModelGlobalControl.trainingTimestampLastModified = modelControl.timestampLastModified
                        inMemory_KeyModelGlobalControl.trainingMinLoss = modelControl.minLoss
                        
                        // rebuild training process data from disk
                        var processIndex = 0 // 0 for training; 1 for validation
                        if let processData = modelControl.trainingProcessDataTrainLoss?.toArray(type: Float32.self) {
                            // We currently assume epochs are always consecutive
                            for (epoch, processDataEpochValue) in processData.enumerated() {
                                inMemory_KeyModelGlobalControl.trainingProcessDataStorageLoss.trainingProcessData[processIndex].epochValueTuples.append(
                                    (epoch: epoch, value: processDataEpochValue)
                                )
                            }
                        }
                        processIndex = 1
                        if let processData = modelControl.trainingProcessDataValidLoss?.toArray(type: Float32.self) {
                            // We currently assume epochs are always consecutive
                            for (epoch, processDataEpochValue) in processData.enumerated() {
                                inMemory_KeyModelGlobalControl.trainingProcessDataStorageLoss.trainingProcessData[processIndex].epochValueTuples.append(
                                    (epoch: epoch, value: processDataEpochValue)
                                )
                            }
                        }
                        
                        // rebuild training process data from disk
                        processIndex = 0 // 0 for training; 1 for validation
                        if let processData = modelControl.trainingProcessDataTrainMetric?.toArray(type: Float32.self) {
                            // We currently assume epochs are always consecutive
                            for (epoch, processDataEpochValue) in processData.enumerated() {
                                inMemory_KeyModelGlobalControl.trainingProcessDataStorageMetric.trainingProcessData[processIndex].epochValueTuples.append(
                                    (epoch: epoch, value: processDataEpochValue)
                                )
                            }
                        }
                        processIndex = 1
                        if let processData = modelControl.trainingProcessDataValidMetric?.toArray(type: Float32.self) {
                            // We currently assume epochs are always consecutive
                            for (epoch, processDataEpochValue) in processData.enumerated() {
                                inMemory_KeyModelGlobalControl.trainingProcessDataStorageMetric.trainingProcessData[processIndex].epochValueTuples.append(
                                    (epoch: epoch, value: processDataEpochValue)
                                )
                            }
                        }
                        
                    } else if modelControl.id == REConstants.ModelControl.indexModelId {
                        inMemory_KeyModelGlobalControl.keyModelUUIDOwnedByIndexModel = modelControl.keyModelUUID ?? REConstants.ModelControl.defaultIndexModelUUID
                        inMemory_KeyModelGlobalControl.indexModelUUID = modelControl.indexModelUUID ?? REConstants.ModelControl.defaultIndexModelUUID
                        
                        inMemory_KeyModelGlobalControl.indexModelWeights = (cnnWeights: cnnWeights, cnnBias: cnnBias, fcWeights: fcWeights, fcBias: fcBias)
                        inMemory_KeyModelGlobalControl.indexState = InMemory_KeyModelGlobalControl.IndexState(rawValue: modelControl.state) ?? .Stale
                        inMemory_KeyModelGlobalControl.indexMaxMetric = InMemory_KeyModelGlobalControl.MaxMetric(rawValue: modelControl.maxMetric) ?? .BalancedAccuracy
                        inMemory_KeyModelGlobalControl.indexCurrentMaxMetric = modelControl.currentMaxMetric
                        inMemory_KeyModelGlobalControl.indexTimestampLastModified = modelControl.timestampLastModified
                        inMemory_KeyModelGlobalControl.indexMinLoss = modelControl.minLoss
                        
                        // rebuild training process data from disk
                        var processIndex = 0 // 0 for training; 1 for validation
                        if let processData = modelControl.trainingProcessDataTrainLoss?.toArray(type: Float32.self) {
                            // We currently assume epochs are always consecutive
                            for (epoch, processDataEpochValue) in processData.enumerated() {
                                inMemory_KeyModelGlobalControl.indexProcessDataStorageLoss.trainingProcessData[processIndex].epochValueTuples.append(
                                    (epoch: epoch, value: processDataEpochValue)
                                )
                            }
                        }
                        processIndex = 1
                        if let processData = modelControl.trainingProcessDataValidLoss?.toArray(type: Float32.self) {
                            // We currently assume epochs are always consecutive
                            for (epoch, processDataEpochValue) in processData.enumerated() {
                                inMemory_KeyModelGlobalControl.indexProcessDataStorageLoss.trainingProcessData[processIndex].epochValueTuples.append(
                                    (epoch: epoch, value: processDataEpochValue)
                                )
                            }
                        }
                        
                        // rebuild training process data from disk
                        processIndex = 0 // 0 for training; 1 for validation
                        if let processData = modelControl.trainingProcessDataTrainMetric?.toArray(type: Float32.self) {
                            // We currently assume epochs are always consecutive
                            for (epoch, processDataEpochValue) in processData.enumerated() {
                                inMemory_KeyModelGlobalControl.indexProcessDataStorageMetric.trainingProcessData[processIndex].epochValueTuples.append(
                                    (epoch: epoch, value: processDataEpochValue)
                                )
                            }
                        }
                        processIndex = 1
                        if let processData = modelControl.trainingProcessDataValidMetric?.toArray(type: Float32.self) {
                            // We currently assume epochs are always consecutive
                            for (epoch, processDataEpochValue) in processData.enumerated() {
                                inMemory_KeyModelGlobalControl.indexProcessDataStorageMetric.trainingProcessData[processIndex].epochValueTuples.append(
                                    (epoch: epoch, value: processDataEpochValue)
                                )
                            }
                        }
                    }
                }
            }


    }
    
    /// Assign the data properties for a new project
    func assignDataControllerProperties(initialSetupDataController: InitialSetupDataController) {
        
        if initialSetupDataController.isNewProject {
            // In the current version, the modelTaskType is determined by the number of classes. This will need to change when addititional tasks (e.g., QA Classification) are enabled.
            numberOfClasses = initialSetupDataController.numberOfClasses
            if numberOfClasses == 2 {
                modelTaskType = ModelTask.binaryClassification
                // This is just to be safe in case this property is used elsewhere (since it is not currently being set by user selection):
                initialSetupDataController.modelTaskType = ModelTask.binaryClassification
            } else {
                modelTaskType = ModelTask.multiclassClassification
                // This is just to be safe in case this property is used elsewhere (since it is not currently being set by user selection):
                initialSetupDataController.modelTaskType = ModelTask.multiclassClassification
            }
//            modelTaskType = initialSetupDataController.modelTaskType
//            if modelTaskType != ModelTask.multiclassClassification {
//                numberOfClasses = 2
//            } else {
//                numberOfClasses = initialSetupDataController.numberOfClasses
//            }
            modelGroup = initialSetupDataController.modelGroup
            defaultPrompt = initialSetupDataController.getConstructedPrompt()
            
            //documentSelectionState = DocumentSelectionState(numberOfClasses: numberOfClasses)
        }
    }
    

    init(projectURL: URL?) {
        self.projectURL = projectURL
        /* These are currently loaded on demand instead
        Task {
            // tokenize -- latin
            self.tokenizer = SentencepieceTokenizer(language: .english, isMultilingual: false)
            // tokenize -- multilingual
            self.multiTokenizer = SentencepieceTokenizer(language: .english, isMultilingual: true)
        } */
    }
    lazy var container: NSPersistentContainer = {
        // may want to check: static let isPackageKey: URLResourceKey
        //print("DataController INIT: \(projectURL?.description)")
        
        
        let container = NSPersistentContainer(name: "DatastoreModel")
        
        let url = projectURL?.appendingPathComponent("InternalStore_lite_v1.sqlite")
        /*
         let description = NSPersistentStoreDescription(url: url!)
         container.persistentStoreDescriptions = [description]
         */
        // from Earthquakes
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
//        print("Database original location: \(description.url?.absoluteString ?? "")")
        
        description.url = url!
        // end Earthquaks
        
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as? NSError {
                fatalError("Unresolved error: \(error), \(error.userInfo)")
            }
        }
        //        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        //        container.viewContext.automaticallyMergesChangesFromParent = true
        //        container.viewContext.undoManager = nil
        //        container.viewContext.shouldDeleteInaccessibleFaults = true
        
        container.viewContext.automaticallyMergesChangesFromParent = false // Note the need to manually merge context and update views
        container.viewContext.name = "viewContext"
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        
        //        print("container.viewContext.automaticallyMergesChangesFromParent: \(container.viewContext.automaticallyMergesChangesFromParent)")
        //        print("container.viewContext.shouldDeleteInaccessibleFaults: \(container.viewContext.shouldDeleteInaccessibleFaults)")
        
        return container
    }()
    
    
    deinit {
        
        print("DataController.swift did deinit")
    }
    // Earthquakes
    /// Creates and configures a private queue context.
    func newTaskContext() -> NSManagedObjectContext {
        // Create a private queue context.
        /// - Tag: newBackgroundContext
        let taskContext = container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }
    
    func addANewEvaluationSet(moc: NSManagedObjectContext) throws {
        
        let fetchRequest = DatasetGlobalControl.fetchRequest()
        fetchRequest.fetchLimit = 1
        let results = try moc.fetch(fetchRequest)

        for datasetControl in results {
            let newDatasetId = datasetControl.nextAvailableDatasetId
            
            let dataset = Dataset(context: moc)
            dataset.id = newDatasetId
//            dataset.internalName = "Additional Eval set"
            dataset.internalName = REConstants.Datasets.getInternalName(datasetId: REConstants.DatasetsEnum.test)
            dataset.userSpecifiedName = REConstants.Datasets.getUserSpecifiedNameForAdditionalEvalSet(datasetIdInt: newDatasetId) //"Eval set (\(newDatasetId))"
            inMemory_Datasets[dataset.id] = InMemory_Dataset(id: dataset.id, internalName: dataset.internalName, count: 0, userSpecifiedName: dataset.userSpecifiedName)
            
            // Update id counter:
            datasetControl.nextAvailableDatasetId = datasetControl.nextAvailableDatasetId + 1
            datasetControl.numberOfEvalSets = datasetControl.numberOfEvalSets + 1
            if moc.hasChanges {
                try moc.save()
                numberOfEvalSets += 1
            }
            
        }
    }
    
    func updateUserSpecifiedDatasetName(datasetIdInt: Int, newName: String, moc: NSManagedObjectContext) throws {
        let fetchRequest = Dataset.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: datasetIdInt))
        fetchRequest.fetchLimit = 1
        let results = try moc.fetch(fetchRequest)
        for dataset in results {
            dataset.userSpecifiedName = newName
        }
        if moc.hasChanges {
            try moc.save()
        }
        // update the in-memory version
        inMemory_Datasets[datasetIdInt]?.userSpecifiedName = newName
    }
    
    func createInitialDatasetStructures(initialSetupDataController: InitialSetupDataController, moc: NSManagedObjectContext) async throws {
        if !initialSetupDataController.isNewProject {
            // update the published properties via the existing database
            // The fetch is on the main thread since there are not that many items and we need to update the UI
            try await MainActor.run {
                let fetchRequest = DatasetGlobalControl.fetchRequest()
                fetchRequest.fetchLimit = 1
                let results = try moc.fetch(fetchRequest)
                //var dbNumberOfEvalSets: Int = 1
                if let datasetControl = results.last {
                    if let modelTaskTypeU = ModelTask(rawValue: datasetControl.modelTaskType), let modelGroupU = SentencepieceConstants.ModelGroup(rawValue: datasetControl.modelGroup) {
                        id = datasetControl.id
                        modelTaskType = modelTaskTypeU
                        modelGroup = modelGroupU
                        numberOfClasses = datasetControl.numberOfClasses
                        numberOfEvalSets = datasetControl.numberOfEvalSets
                        
                        if let existingDefaultPrompt = datasetControl.defaultPrompt {
                            defaultPrompt = existingDefaultPrompt
                        }
                        // Retrieve label string names
                        if let labelNames = datasetControl.labelNames {
                            for labelName in labelNames {
                                labelToName[labelName.label] = labelName.userSpecifiedName
                            }
                        }
                        
                        //we always retrieve this from the db before using: datasetGlobalControl.nextAvailableDatasetId
                    }
                }
                // Retrieve datasets
                let datasetFetchRequest = Dataset.fetchRequest()
                datasetFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Dataset.id, ascending: true)]
                datasetFetchRequest.fetchLimit = REConstants.Datasets.maxTotalDatasets
                let datasetResults = try moc.fetch(datasetFetchRequest)
                for dataset in datasetResults {
                    inMemory_Datasets[dataset.id] = InMemory_Dataset(id: dataset.id, internalName: dataset.internalName, count: dataset.count, userSpecifiedName: dataset.userSpecifiedName) //, documentIds: nil))
                }
                
                // also add the placeholder:
                inMemory_Datasets[REConstants.Datasets.placeholderDatasetId] = InMemory_Dataset(id: REConstants.Datasets.placeholderDatasetId, internalName: REConstants.Datasets.placeholderDatasetName, count: 0, userSpecifiedName: REConstants.Datasets.placeholderDatasetDisplayName)
                // refresh temporary storage
                try refreshTemporaryStorageDatasetMainActor(moc: moc)
                
                // The application will be unusable if the required datasplits (particularly Training and Calibration) do not exist, so we recreate them if for some reason the database is corrupted. This should essentially never happen, but could happen in theory if a user immediately closes or runs out of space when deleting one of the required datasplits.
                var requiredDatasplitIsMissing: Bool = false
                for datasetId in REConstants.DatasetsEnum.allCases {
                    if inMemory_Datasets[datasetId.rawValue] == nil {  // unexpectedly a required datasplit is missing
                        requiredDatasplitIsMissing = true
                        let dataset = Dataset(context: moc)
                        dataset.id = datasetId.rawValue
                        dataset.internalName = REConstants.Datasets.getInternalName(datasetId: datasetId)
                        dataset.userSpecifiedName = REConstants.Datasets.getUserSpecifiedName(datasetId: datasetId)
                        inMemory_Datasets[dataset.id] = InMemory_Dataset(id: dataset.id, internalName: dataset.internalName, count: 0, userSpecifiedName: dataset.userSpecifiedName)
                    }
                }
                if requiredDatasplitIsMissing && moc.hasChanges {
                    try moc.save()
                }
                

                // retrieve training/index control
                try getModelControlPropertiesFromDatabase(moc: moc)
                
                
                let uncertaintyStatisticsInitial = UncertaintyStatistics(uncertaintyModelUUID: REConstants.ModelControl.defaultUncertaintyModelUUID, indexModelUUID: REConstants.ModelControl.defaultIndexModelUUID, alpha: REConstants.Uncertainty.defaultConformalAlpha, qMax: REConstants.Uncertainty.defaultQMax, numberOfClasses: numberOfClasses)
                
                self.uncertaintyStatistics = uncertaintyStatisticsInitial
                
                self.documentSelectionState_DocumentsOverview = DocumentSelectionState(numberOfClasses: numberOfClasses)
                self.documentSelectionState_CompareGraph = DocumentSelectionState(numberOfClasses: numberOfClasses)
                
                // Currently, always re-init documentSelectionState
                //documentSelectionState = DocumentSelectionState(numberOfClasses: numberOfClasses)
                
                /*let datasetIdInt64 = Int64(REConstants.DatasetsEnum.train.rawValue)
                let fetchRequest = Dataset.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: datasetIdInt64))
                let results = try moc.fetch(fetchRequest)
                for dataset in results {
                    if let modelTaskTypeU = ModelTask(rawValue: Int(dataset.modelTaskType)), let modelGroupU = SentencepieceConstants.ModelGroup(rawValue: Int(dataset.modelGroup)) {
                        modelTaskType = modelTaskTypeU
                        modelGroup = modelGroupU
                        numberOfClasses = Int(dataset.numberOfClasses)
                    }
                }*/
            }
            // Existing structure, if present, will overwrite the defaults:
            try await uncertaintyStatistics?.restoreFromDisk(moc: moc)
            
        } else { // Create the initial dataset structures
            try await MainActor.run {
                assignDataControllerProperties(initialSetupDataController: initialSetupDataController)
                
                let datasetGlobalControl = DatasetGlobalControl(context: moc)
                datasetGlobalControl.id = id  // use the UUID created on class iniit
//                datasetGlobalControl.modelTaskType = Int64(modelTaskType.rawValue)
//                datasetGlobalControl.modelGroup = Int64(modelGroup.rawValue)
//                datasetGlobalControl.numberOfClasses = Int64(numberOfClasses)
                datasetGlobalControl.modelTaskType = modelTaskType.rawValue
                datasetGlobalControl.modelGroup = modelGroup.rawValue
                datasetGlobalControl.numberOfClasses = numberOfClasses
                datasetGlobalControl.numberOfEvalSets = 1
                datasetGlobalControl.nextAvailableDatasetId = REConstants.Datasets.numberOfRequiredDatasets
                datasetGlobalControl.defaultPrompt = defaultPrompt
                
                datasetGlobalControl.version = REConstants.ProgramIdentifiers.version

                for datasetId in REConstants.DatasetsEnum.allCases {
                    let dataset = Dataset(context: moc)
                    dataset.id = datasetId.rawValue  //Int64(datasetId.rawValue)
                    dataset.internalName = REConstants.Datasets.getInternalName(datasetId: datasetId)
                    dataset.userSpecifiedName = REConstants.Datasets.getUserSpecifiedName(datasetId: datasetId)
                    inMemory_Datasets[dataset.id] = InMemory_Dataset(id: dataset.id, internalName: dataset.internalName, count: 0, userSpecifiedName: dataset.userSpecifiedName) //, documentIds: nil))
//                    inMemory_Datasets[dataset.id] = InMemory_Dataset(id: dataset.id, internalName: dataset.internalName, count: Int64(0), userSpecifiedName: dataset.userSpecifiedName) //, documentIds: nil))
                    
                }
                
                // also add the placeholder:
                let dataset = Dataset(context: moc)
                dataset.id = REConstants.Datasets.placeholderDatasetId
                dataset.internalName = REConstants.Datasets.placeholderDatasetName
                dataset.userSpecifiedName = REConstants.Datasets.placeholderDatasetDisplayName
                inMemory_Datasets[REConstants.Datasets.placeholderDatasetId] = InMemory_Dataset(id: REConstants.Datasets.placeholderDatasetId, internalName: REConstants.Datasets.placeholderDatasetName, count: 0, userSpecifiedName: REConstants.Datasets.placeholderDatasetDisplayName)
                
                
                // Add label structures
                for label in 0..<numberOfClasses {
                    let labelName = LabelName(context: moc)
                    labelName.label = label
                    labelName.userSpecifiedName = String(label)
                    datasetGlobalControl.addToLabelNames(labelName)
                    labelToName[label] = String(label)
                }
                // Add OOD and unlabeled
                let labelName = LabelName(context: moc)
                labelName.label = REConstants.DataValidator.oodLabel
                labelName.userSpecifiedName = REConstants.DataValidator.getDefaultLabelName(label: REConstants.DataValidator.oodLabel)
                datasetGlobalControl.addToLabelNames(labelName)
                labelToName[REConstants.DataValidator.oodLabel] = REConstants.DataValidator.getDefaultLabelName(label: REConstants.DataValidator.oodLabel)
                
                let labelName2 = LabelName(context: moc)
                labelName2.label = REConstants.DataValidator.unlabeledLabel
                labelName2.userSpecifiedName = REConstants.DataValidator.getDefaultLabelName(label: REConstants.DataValidator.unlabeledLabel)
                datasetGlobalControl.addToLabelNames(labelName2)
                labelToName[REConstants.DataValidator.unlabeledLabel] = REConstants.DataValidator.getDefaultLabelName(label: REConstants.DataValidator.unlabeledLabel)

                if moc.hasChanges {
                    try moc.save()
                }
                                
                // selection state
                self.documentSelectionState_DocumentsOverview = DocumentSelectionState(numberOfClasses: numberOfClasses)
                self.documentSelectionState_CompareGraph = DocumentSelectionState(numberOfClasses: numberOfClasses)
            }
        }
    }
    
}













