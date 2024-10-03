//
//  REConstants+StringLabels.swift
//  Alpha1
//
//  Created by A on 8/13/23.
//

import Foundation
import SwiftUI

extension REConstants {
    struct MenuNames {
        static let setupName = "Data"
        static let learnName = "Learn"
        static let exploreName = "Explore"
        static let compareName = "Compare"
        static let discoverName = "Discover"
        static let composeName = "Compose"
        
        static let selectName = "Select"
        static let labelsName = "Labels"
    }
    struct SelectionDisplayLabels {
        static let dataPartitionSelectionTab = "Partition(s)"
        
        static let showAllPartitionsLabel = "Show all available partitions"
        
        static let selectionInitAlertMessage = "Currently showing the Training set. Click Select to change."
    }
    struct CategoryDisplayLabels {
        static let labelFull = "Label"
        static let predictionFull = "Prediction"  // c.f., predictedFull
        static let calibratedProbabilityFull = "Calibrated Probability"
        static let calibrationReliabilityFull = "Calibration Reliability"
        static let predictedFull = "Predicted class"
        static let qFull = "Similarity to Training (q)"
        static let dFull = "Distance to Training (d)"
        static let fFull = "f(x) Magnitude"
        static let sizeFull = "Partition Size (in Calibration)"
        
        static let qShort = "Similarity"
        static let qVar = "q" // this should rarely be used
        static let dShort = "Distance"
        static let dVar = "d"
        static let fShort = "Magnitude" // generally use fFull
        static let fVar = "f(x)"
        // These two should be used sparingly:
        static let sizeShort = "Partition Size" // generally use sizeFull
        static let sizeVar = "size"
        
        static let qdfPartitionLabel = "Similarity-Distance-Magnitude"
        static let qdfGradient = LinearGradient(
            colors: [.reGreenBrighter, .reSlateBlueBrighter], //[.reGreen, .reSlateBlue],
            startPoint: .leading,
            endPoint: .trailing
        )
        static let qdfPartitionLabel_TextStruct: Text = Text("Similarity-Distance-Magnitude").foregroundStyle(qdfGradient)
        
        static let classLabelAxisLabel = "Class Label"
        static let predictedClassLabelAxisLabel = "Predicted Class"
        //static let groundtruthClassLabelAxisLabel = "Ground-truth Class" // use classLabelAxisLabel
        
        static let proportionLabel = "Proportion"
        static let currentSelectionLabel = "Current selection"
        static let currentViewLabel = "Current view"
        static let currentViewSampleLabel = "Current view sample"
        static let accuracyLabel = "Accuracy"
    }
    struct PropertyDisplayLabel {
        static let attributesFull = "Reexpression Attributes"
    }
    
    struct Compare {
        static let noDocumentsAvailable = "No documents are available in the current selection."
        static let graphViewMenu = "Graph"
        static let overviewViewMenu = "Overview"
    }
    struct GeneralErrors {
        static let coreDataSaveMessage = "Unable to save update"
    }
    
    struct DataDetailsView {
        static let dateAdded = "Date on which the document was originally uploaded."
    }
    
    struct ExperimentalMode {
        static let experimentalModeFull = "Experimental mode"
        static let experimentalModeDisclaimer = "Some functionality may be disabled or limited when in **\(ExperimentalMode.experimentalModeFull)**, which is Beta software."
        static let experimentalModeDisableDisclaimer = "**\(ExperimentalMode.experimentalModeFull)** is automatically enabled if your Mac does not meet our base performance requirements and cannot be manually enabled or disabled."
        
        static let noticeToEnableExperimentalMode = """
        **\(REConstants.ProgramIdentifiers.mainProgramName)** is a high-performance on-device machine learning data analysis platform.\n\nUnfortunately, based on our estimates, it appears your Mac does not meet our base performance requirements, which is M1 Max with 32 GPU cores or higher (M1 Max 32 cores, M1 Ultra, M2 Max, M2 Ultra, etc.), with 64GB of memory or higher. You may continue in **\(REConstants.ExperimentalMode.experimentalModeFull)**, which is Beta software with limited functionality, and which will be enabled automatically and cannot be disabled on this computer with this version of the Software. In particular, in **\(REConstants.ExperimentalMode.experimentalModeFull)** not all of the models are available when creating new projects (namely, the higher parameter models), and it is not possible to load project files created with some models.\n\nIn short, your system is an out-of-distribution prediction for our performance tests; it may work, but it may not. We recommend backing up your computer and files before using the Software in **\(REConstants.ExperimentalMode.experimentalModeFull)**. Our Terms of Service may provide additional details.\n\nIf you have time, we would love to hear your feedback as we aim to bring **\(REConstants.ProgramIdentifiers.mainProgramName)** to more Apple devices and platforms. See our website for contact information and feedback forms. Thanks in advance!
        """
    }
}

