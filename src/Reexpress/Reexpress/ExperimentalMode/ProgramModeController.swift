//
//  ProgramModeController.swift
//  Reexpress
//
//  Created by A on 10/8/23.
//

import Foundation
import CoreML

class ProgramModeController: ObservableObject {
    enum ProgramMode: Int, CaseIterable {
        case loading = 0
        case minAvailable = 1
        case upto4Billion = 2
    }
    
    @Published var programMode: ProgramMode = .loading //.minAvailable //.upto4Billion
    var isExperimentalMode: Bool {
        return programMode == .loading || programMode == .minAvailable
    }
    var batchSize: Int {
        switch programMode {
        case .loading:  // in principle, this case should never be reached
            return 1
        case .minAvailable:
            return 1
        case .upto4Billion:
            return 100
        }
    }
    private var modeDeterminationTask: Task<Void, Error>?
    deinit {
        modeDeterminationTask?.cancel()
    }
    func determineProgramMode() {
        if programMode == .loading {  // only need to check once
            modeDeterminationTask = Task {
                var gpuIsPresent = false // if false, the program state will (by design) stay stuck on Loading
                var fullComputeAvailability = false
                for computeDevice in MLComputeDevice.allComputeDevices {
                    switch computeDevice {
                    case .gpu(let gpuComputeDevice):
                        // These are based on a M1 Max Macbook Pro with M1 Max 32 cores and 64gb memory
                        if gpuComputeDevice.metalDevice.maxBufferLength > 38000000000 && gpuComputeDevice.metalDevice.recommendedMaxWorkingSetSize > 51000000000 {
                            fullComputeAvailability = true
                        }
                        gpuIsPresent = true
                    case .cpu(_):
                        break
                    case .neuralEngine(_):
                        break
                    @unknown default:
                        break
                    }
                }
                let fullComputeAvailability_Const = fullComputeAvailability
                let gpuIsPresent_Const = gpuIsPresent
                await MainActor.run {
                    if gpuIsPresent_Const {
                        if fullComputeAvailability_Const {
                            self.programMode = .upto4Billion
                        } else {
                            self.programMode = .minAvailable
                        }
                    }
                    // Uncomment this to force entering Experimental mode for debug purposes:
                    //self.programMode = .minAvailable
                }
            }
        }
    }
    
    func isModelCompatibleWithCurrentProgramMode(modelGroup: SentencepieceConstants.ModelGroup) -> Bool {
        switch programMode {
        case .loading:
            return false  // this should not normally be reached at this point
        case .minAvailable:
            return modelGroup == .Fastest
        case .upto4Billion:
            return true
        }
    }
}

