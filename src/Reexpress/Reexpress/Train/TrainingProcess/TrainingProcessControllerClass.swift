//
//  TrainingProcessControllerClass.swift
//  Alpha1
//
//  Created by A on 7/20/23.
//

import Foundation

class TrainingProcessController: ObservableObject {
    
    @Published var epochsString = "\(REConstants.KeyModelConstraints.defaultMaxEpochs)"
    var epochs: Int {
        let converted = Int(Float(epochsString) ?? Float(REConstants.KeyModelConstraints.defaultMaxEpochs))
        switch converted {
        case 1..<REConstants.KeyModelConstraints.maxAllowedEpochs:
            return converted
        default:
            return REConstants.KeyModelConstraints.defaultMaxEpochs
        }
    }
    @Published var learningRateString = "\(REConstants.KeyModelConstraints.defaultLearningRate)" //"0.001" //0.0001 (default to lower if fine-tuning)
    var learningRate: Float32 {
        let converted = Float(learningRateString) ?? REConstants.KeyModelConstraints.defaultLearningRate
        switch converted {
        case 0.000001..<1:
            return converted
        default:
            return REConstants.KeyModelConstraints.defaultLearningRate
        }
    }
    
    let batchSize: Int = REConstants.KeyModelConstraints.defaultBatchSize
    //    @Published var batchSizeString = "\(REConstants.KeyModelConstraints.defaultBatchSize)"
    //    var batchSize: Int {
    //        let converted = Int(Float(batchSizeString) ?? Float(REConstants.KeyModelConstraints.defaultBatchSize))
    //        switch converted {
    //        case 1..<REConstants.KeyModelConstraints.maxAllowedBatchSize:
    //            return converted
    //        default:
    //            return REConstants.KeyModelConstraints.defaultBatchSize
    //        }
    //    }
    
    let numberOfThreads = REConstants.KeyModelConstraints.numberOfThreads
    //@Published var validationFeatureProviders: [FeatureProviderType]?
    
    @Published var useDeacySchedule = false
    @Published var decayScheduleEpochString = "\(REConstants.KeyModelConstraints.defaultDecayEpoch)"
    @Published var decayScheduleFactorString = "\(REConstants.KeyModelConstraints.defaultDecayFactor)"
    var decaySchedule: (epoch: Int, factor: Float) {
        var convertedEpoch = Int(Float(decayScheduleEpochString) ?? Float(REConstants.KeyModelConstraints.defaultDecayEpoch))
        switch convertedEpoch {
        case 1..<REConstants.KeyModelConstraints.maxAllowedEpochs:
            break
        default:
            convertedEpoch = REConstants.KeyModelConstraints.defaultDecayEpoch
        }
        var convertedFactor = Float(decayScheduleFactorString) ?? REConstants.KeyModelConstraints.defaultDecayFactor
        switch convertedFactor {
        case 1..<100.1:
            break
        default:
            convertedFactor = REConstants.KeyModelConstraints.defaultDecayFactor
        }
        return (epoch: convertedEpoch, factor: convertedFactor)
    }
    // Additional options if existing weights are present:
    @Published var ignoreExistingWeights = false
    @Published var ignoreExistingRunningBestMaxMetric = false
    
    //   train(modelControlIdString: String, totalEpochs: Int = 20, prevRunningBestMaxMetric: Float = 0, decaySchedule: (epoch: Int, factor: Float) = (epoch: 1000, factor: 1.0), dataController: DataController, moc: NSManagedObjectContext, validationFeatureProviders: [FeatureProviderType])
    
    init() {
        
    }
}
