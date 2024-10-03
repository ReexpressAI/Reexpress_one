//
//  TrainingProcessDataStorage.swift
//  Alpha1
//
//  Created by A on 7/22/23.
//

import SwiftUI

typealias TrainingDataPointType = (id: String, epoch: Int, value: Float32)

struct TrainingProcessDataStorage {
    struct MetricSeries: Identifiable {
        /// The dataset identifier for the series.
        var id: String
        var epochValueTuples: [(epoch: Int, value: Float32)]
    }
    // data acquired during training
//    var trainingProcessData: [MetricSeries] = [
//        .init(id: Constants.trainingSetIdString, epochValueTuples: [
//            (epoch: 0, value: 25.0),
//            (epoch: 1, value: 15.0),
//            (epoch: 2, value: 12.0),
//            (epoch: 3, value: 12.0)
//        ]),
//        .init(id: Constants.validationSetIdString, epochValueTuples: [
//            (epoch: 0, value: 35.0),
//            (epoch: 1, value: 5.0),
//            (epoch: 2, value: 11.0),
//            (epoch: 3, value: 17.0)
//        ]),
//    ]
    var trainingProcessData: [MetricSeries] = [
        .init(id: Constants.trainingSetIdString, epochValueTuples: [
        ]),
        .init(id: Constants.validationSetIdString, epochValueTuples: [
        ]),
    ]
    // could move to a separate file with all contant extensions
    struct Constants {
        static let trainingSetIdString = "Training"
        static let validationSetIdString = "Calibration"
                
        static let colorDictionary: [String: Color] = [trainingSetIdString: .red, validationSetIdString: .blue]
        static let imageDictionary: [String: Image] = [
            trainingSetIdString: Image(systemName: "circle.fill"),
            validationSetIdString: Image(systemName: "square.fill")
        ]
    }
    static func getColorForDataSet(id: String) -> Color {
        if let color = Constants.colorDictionary[id] {
            return color
        }
        return .blue
    }
    static func getImageMarkerForDataSet(id: String) -> Image {
        if let image = Constants.imageDictionary[id] {
            return image
        }
        return Image(systemName: "square.fill")
    }
    mutating func resetTrainingProcessData() {
        trainingProcessData = [
            .init(id: Constants.trainingSetIdString, epochValueTuples: [
            ]),
            .init(id: Constants.validationSetIdString, epochValueTuples: [
            ]),
        ]
    }
}



