//
//  KeyModel.swift
//  BNNS-Training-Sample
//
//  Created by A on 3/28/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import Accelerate


typealias FeatureProviderType = (Float32, [Float32], String)  // Label, Input dense vector, document/instance id
typealias OutputPredictionType = (id: String, softmax: [Float32], predictedClass: Int, exemplar: [Float32]?)  // document/instance id, softmax across all classes, predicted class as Int, exemplar vector (if applicable)
typealias OutputFeaturePredictionType = (predictedClass: Int, predictedSoftmax: Float32, sentenceIndex: Int)  // features *within* a document

typealias OutputFullAnalysisPredictionType = (frozenNetworkDocumentEmbeddingsArray: [Float32]?, documentLevelPrediction: OutputPredictionType?, featureLevelAnalysisMatchesDocLevel: OutputFeaturePredictionType?, featureLevelAnalysisInconsistentWithDocLevel: OutputFeaturePredictionType?)
typealias OutputFullAnalysisWithFeaturesPredictionType = (documentLevelPrediction: OutputPredictionType?, featureLevelAnalysisMatchesDocLevel: OutputFeaturePredictionType?, featureLevelAnalysisInconsistentWithDocLevel: OutputFeaturePredictionType?, documentExemplarCompressed: [Float32], documentSentencesRanges: [Range<String.Index>], startingSentenceArrayIndexOfDocument: Int, sentenceExemplarsCompressed: [Float32])
//typealias OutputFullAnalysisWithFeaturesPredictionType = (documentLevelPrediction: OutputPredictionType?, featureLevelAnalysisMatchesDocLevel: OutputFeaturePredictionType?, featureLevelAnalysisInconsistentWithDocLevel: OutputFeaturePredictionType?, documentExemplarCompressed: [Float32], documentSentencesRangesLower: [Int], documentSentencesRangesUpper: [Int], startingSentenceArrayIndexOfDocument: Int, sentenceExemplarsCompressed: [Float32])

class KeyModel {
    
    typealias ModelWeights = (cnnWeights: [Float]?, cnnBias: [Float]?, fcWeights: [Float]?, fcBias: [Float]?)
    
    var numberOfClasses: Int
    // Specify `useClientPointer` to instruct the layers to keep the provided
    // pointers at creation time, and to work directly from that data rather than
    // use internal copies of the data.
    var filterParameters: BNNSFilterParameters
    var batchSize: Int
        
    var oneHotLabels: BNNSNDArrayDescriptor
    
    // The `input` array descriptor contains the images of the digits.
    var input: BNNSNDArrayDescriptor

    let randomGenerator: BNNS.RandomGenerator = {
        guard let rng = BNNS.RandomGenerator(method: .aesCtr) else {
            fatalError("Unable to create `RandomGenerator`.")
        }
        return rng
    }()
    
    // MARK: Convolution
    var keyModelInputSize: Int
    var numberOfFilterMaps: Int
    var convolutionWeights: BNNSNDArrayDescriptor
    var convolutionBias: BNNSNDArrayDescriptor
    var batchCNNOutput: BNNSNDArrayDescriptor
    var cnnLayer: BNNS.ConvolutionLayer

    // Gradient Descriptors
    var convolutionInputGradient: BNNSNDArrayDescriptor
    var convolutionWeightGradient: BNNSNDArrayDescriptor
    var convolutionBiasGradient: BNNSNDArrayDescriptor
    
    // Optimizer Accumulator Descriptors
    var convolutionWeightAccumulator1: BNNSNDArrayDescriptor
    var convolutionWeightAccumulator2: BNNSNDArrayDescriptor
    var convolutionBiasAccumulator1: BNNSNDArrayDescriptor
    var convolutionBiasAccumulator2: BNNSNDArrayDescriptor
    
        
    // MARK: Fully-Connected
    var fullyConnectedWeights: BNNSNDArrayDescriptor
    var fullyConnectedBias: BNNSNDArrayDescriptor
    var fullyConnectedOutput: BNNSNDArrayDescriptor
    var fullyConnectedLayer: BNNS.FullyConnectedLayer
    
    var fullyConnectedInputGradient: BNNSNDArrayDescriptor
    var fullyConnectedWeightGradient: BNNSNDArrayDescriptor
    var fullyConnectedBiasGradient: BNNSNDArrayDescriptor
    var fullyConnectedWeightAccumulator1: BNNSNDArrayDescriptor
    var fullyConnectedWeightAccumulator2: BNNSNDArrayDescriptor
    var fullyConnectedBiasAccumulator1: BNNSNDArrayDescriptor
    var fullyConnectedBiasAccumulator2: BNNSNDArrayDescriptor
    
    // MARK: Optimizer
    var adam: BNNS.AdamOptimizer
    
    // MARK: Loss
    var lossOutput: BNNSNDArrayDescriptor
    var lossLayer: BNNS.LossLayer
    var lossInputGradient: BNNSNDArrayDescriptor
    
    // MARK: softmax
    var softmaxOutput: BNNSNDArrayDescriptor
    var softmaxLayer: BNNS.ActivationLayer
    
    init(batchSize: Int = 32, numberOfThreads: Int = 10, numberOfClasses: Int, keyModelInputSize: Int, numberOfFilterMaps: Int = 1000, learningRate: Float = 0.01, initialModelWeights: ModelWeights?) {
        // MARK: Global init
        self.numberOfClasses = numberOfClasses
        self.filterParameters = BNNSFilterParameters(
            flags: BNNSFlags.useClientPointer.rawValue,
            n_threads: numberOfThreads,
            alloc_memory: nil,
            free_memory: nil)
        self.batchSize = batchSize
        self.oneHotLabels = BNNSNDArrayDescriptor.allocateUninitialized(
            scalarType: Float.self,
            shape: .vector(numberOfClasses),
            batchSize: batchSize)
        
        self.keyModelInputSize = keyModelInputSize
        self.numberOfFilterMaps = numberOfFilterMaps
        
        self.input = BNNSNDArrayDescriptor.allocateUninitialized(
            scalarType: Float.self,
            shape: .imageCHW(keyModelInputSize,
                             1,
                             1),
            batchSize: batchSize)
        
        
        // MARK: Convolution init
        
        let convolutionWeightsShape = BNNS.Shape.convolutionWeightsOIHW(
            keyModelInputSize, // The convolution kernel width (pixels).
            1,  //  The convolution kernel height (pixels).
            1,  // The number of input channels.
            numberOfFilterMaps)  // The number of output channels.
        
        if let initialModelWeights = initialModelWeights, let initialConvolutionWeights = initialModelWeights.cnnWeights {
            self.convolutionWeights = BNNSNDArrayDescriptor.allocate(
                initializingFrom: initialConvolutionWeights,
                shape: convolutionWeightsShape)
        } else { // new weights:
            guard let cnnDesc = BNNSNDArrayDescriptor.allocate(
                randomUniformUsing: randomGenerator,
                range: Float(-0.5)...Float(0.5),
                shape: convolutionWeightsShape) else {
                fatalError("Unable to create `convolutionWeightsArray`.")
            }
            
            
            self.convolutionWeights = cnnDesc
        }
        if let initialModelWeights = initialModelWeights, let initialConvolutionBias = initialModelWeights.cnnBias {
            self.convolutionBias = BNNSNDArrayDescriptor.allocate(
                initializingFrom: initialConvolutionBias,
                shape: .vector(numberOfFilterMaps))
        } else {
            self.convolutionBias = BNNSNDArrayDescriptor.allocate(
                repeating: Float(0),
                shape: .vector(numberOfFilterMaps))
        }
        self.batchCNNOutput = BNNSNDArrayDescriptor.allocateUninitialized(
            scalarType: Float.self,
            shape: .imageCHW(1,
                             1,
                             numberOfFilterMaps),
            batchSize: batchSize)
        
        guard let cnnLayer = BNNS.ConvolutionLayer(
            type: .standard,
            input: input,
            weights: convolutionWeights,
            output: batchCNNOutput,
            bias: convolutionBias,
            padding: .zero,
            activation: .identity, // we separate relu into another layer since we do not want relu applied to the exemplar vectors
            groupCount: 1,
            stride: (1, 1),
            dilationStride: (1, 1),
            filterParameters: filterParameters
        ) else {
            fatalError("unable to create fusedConvBatchnormLayer")
        }
        
        self.cnnLayer = cnnLayer
        
        self.convolutionInputGradient = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: input.shape,
            batchSize: batchSize)
        
        self.convolutionWeightGradient = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: convolutionWeights.shape)
        
        self.convolutionBiasGradient = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: convolutionBias.shape)
        
        
        // Optimizer Accumulator Descriptors
        self.convolutionWeightAccumulator1 = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: convolutionWeights.shape)
        self.convolutionWeightAccumulator2 = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: convolutionWeights.shape)
        self.convolutionBiasAccumulator1 = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: convolutionBias.shape)
        self.convolutionBiasAccumulator2 = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: convolutionBias.shape)
                
        // MARK: Fully-Connected init
        if let initialModelWeights = initialModelWeights, let initialFullyConnectedWeights = initialModelWeights.fcWeights {
            self.fullyConnectedWeights = BNNSNDArrayDescriptor.allocate(
                initializingFrom: initialFullyConnectedWeights,
                shape: .matrixRowMajor(numberOfFilterMaps,
                                       numberOfClasses))
        } else {
            guard let fcDesc = BNNSNDArrayDescriptor.allocate(
                randomUniformUsing: randomGenerator,
                range: Float(-0.5)...Float(0.5),
                shape: .matrixRowMajor(numberOfFilterMaps,
                                       numberOfClasses)) else {
                fatalError("Unable to create `fullyConnectedWeightsArray`.")
            }
            self.fullyConnectedWeights = fcDesc
        }
        if let initialModelWeights = initialModelWeights, let initialFullyConnectedBias = initialModelWeights.fcBias {
            self.fullyConnectedBias = BNNSNDArrayDescriptor.allocate(
                initializingFrom: initialFullyConnectedBias,
                shape: .vector(numberOfClasses))
        } else {
            self.fullyConnectedBias = BNNSNDArrayDescriptor.allocate(
                repeating: Float(0),
                shape: .vector(numberOfClasses))
        }
        self.fullyConnectedOutput = BNNSNDArrayDescriptor.allocateUninitialized(
            scalarType: Float.self,
            shape: .vector(numberOfClasses),
            batchSize: batchSize)
        
        let fcInputdesc = BNNSNDArrayDescriptor(dataType: .float,
                                         shape: .vector(numberOfFilterMaps))
        
        guard let fullyConnectedLayerInit = BNNS.FullyConnectedLayer(
                input: fcInputdesc,
                output: fullyConnectedOutput,
                weights: fullyConnectedWeights,
                bias: fullyConnectedBias,
                activation: .identity,
                filterParameters: filterParameters) else {
            fatalError("Unable to create `fullyConnectedLayer`.")
        }
        self.fullyConnectedLayer = fullyConnectedLayerInit
        self.fullyConnectedInputGradient = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: .vector(numberOfFilterMaps),
            batchSize: batchSize)
        self.fullyConnectedWeightGradient = BNNSNDArrayDescriptor.allocateUninitialized(
            scalarType: Float.self,
            shape: fullyConnectedWeights.shape)
        self.fullyConnectedBiasGradient = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: fullyConnectedBias.shape)
        self.fullyConnectedWeightAccumulator1 = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: fullyConnectedWeights.shape)
        self.fullyConnectedWeightAccumulator2 = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: fullyConnectedWeights.shape)
        self.fullyConnectedBiasAccumulator1 = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: fullyConnectedBias.shape)
        self.fullyConnectedBiasAccumulator2 = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: fullyConnectedBias.shape)
        
        // MARK: Optimizer init
        adam = BNNS.AdamOptimizer(learningRate: learningRate, //0.01,
                                  timeStep: 1,
                                  gradientScale: 1,
                                  regularizationScale: 0.01,
                                  gradientClipping: .byValue(bounds: -0.5 ... 0.5),
                                  regularizationFunction: BNNSOptimizerRegularizationL2)
        
        
        // MARK: Loss init
        // This sample reduces loss to a single value.
        let lossOutputWidth = 1
        self.lossOutput = BNNSNDArrayDescriptor.allocateUninitialized(
            scalarType: Float.self,
            shape: .vector(lossOutputWidth))
        guard let lossLayerInit = BNNS.LossLayer(input: fullyConnectedOutput,
                                             output: lossOutput,
                                                 lossFunction: .softmaxCrossEntropy(labelSmoothing: 0),
                                             lossReduction: .reductionMean,
                                             filterParameters: filterParameters) else {
            fatalError("Unable to create `lossLayer`.")
        }
        
        self.lossLayer = lossLayerInit
        self.lossInputGradient = BNNSNDArrayDescriptor.allocate(
            repeating: Float(0),
            shape: .vector(numberOfClasses),
            batchSize: batchSize)
        
        // MARK: softmax init
        self.softmaxOutput = BNNSNDArrayDescriptor.allocateUninitialized(
            scalarType: Float.self,
            shape: .vector(numberOfClasses),
            batchSize: batchSize)
        guard let softmaxLayerInit = BNNS.ActivationLayer(function: .softmax, input: fullyConnectedOutput, output: softmaxOutput, filterParameters: filterParameters) else
        {
            fatalError("Unable to create `softmaxLayer`.")
        }
        
        self.softmaxLayer = softmaxLayerInit
    
    }
    



    
    deinit {
        oneHotLabels.deallocate()
        input.deallocate()
        convolutionWeights.deallocate()
        convolutionBias.deallocate()
        batchCNNOutput.deallocate()
        
        fullyConnectedWeights.deallocate()
        fullyConnectedBias.deallocate()
        fullyConnectedOutput.deallocate()
        lossOutput.deallocate()
        lossInputGradient.deallocate()
        fullyConnectedInputGradient.deallocate()
        fullyConnectedWeightGradient.deallocate()
        fullyConnectedBiasGradient.deallocate()
        fullyConnectedWeightAccumulator1.deallocate()
        fullyConnectedWeightAccumulator2.deallocate()
        fullyConnectedBiasAccumulator1.deallocate()
        fullyConnectedBiasAccumulator2.deallocate()
        
        convolutionInputGradient.deallocate()
        convolutionWeightGradient.deallocate()
        convolutionBiasGradient.deallocate()
                
        convolutionWeightAccumulator1.deallocate()
        convolutionWeightAccumulator2.deallocate()
        convolutionBiasAccumulator1.deallocate()
        convolutionBiasAccumulator2.deallocate()
        
        
        // MARK: added 2023-07-04: (This was previously missing.)
        softmaxOutput.deallocate()
        
        //BNNSFilterDestroy(cnnLayer)
        //print("Did deinit KeyModel")
    }
}
