//
//  REConstants+UserDefaults.swift
//  Alpha1
//
//  Created by A on 8/22/23.
//

import Foundation

extension REConstants {
    struct UserDefaults {
        static let showFeaturesInDocumentText: String = "showFeaturesInDocumentText"
        static let documentFontSize: String = "documentFontSize"
        static let showLeadingFeatureInconsistentWithDocumentLevelInDocumentText: String = "showLeadingFeatureInconsistentWithDocumentLevelInDocumentText"
        static let showSemanticSearchFocusInDocumentText: String = "showSemanticSearchFocusInDocumentText"
        
        static let documentTextOpacity: String = "documentTextOpacity"
        static let documentTextDefaultOpacity: Double = 0.9 //0.75
        static let documentTextMinAllowedOpacity: Double = 0.75
        
        static let defaultDocumentFontSize: CGFloat = 16.0
        static let maxDocumentFontSize: CGFloat = 32.0
        static let minDocumentFontSize: CGFloat = 12.0
        
        
        static let promptFrameHeightStringKey: String = "promptFrameHeight"
        static let promptFrameBaseHeight: Double = 60
        static let promptFrameExpandedHeight: Double = 260
        
        static let documentFrameHeightStringKey: String = "documentFrameHeight"
        static let documentFrameBaseHeight: Double = 260
        static let documentFrameExpandedHeight: Double = 460
        
        // Additional view states
        static let exploreTableWidthIsMaxKey: String = "exploreTableWidthIsMaxKey"
        
        static let compareChartHeightStringKey: String = "compareChartHeightStringKey"
        static let compareChartDefaultHeight: Double = 250
        static let compareChartExpandedHeight: Double = 500
        
        static let showingGraphViewSummaryStatisticsStringKey: String = "showingGraphViewSummaryStatisticsStringKey"
        static let showingGraphViewSummaryStatisticsStringKeyDefault: Bool = true
        
        static let addDataInstructions_showingFieldDetailsStringKey: String = "addDataInstructions_showingFieldDetailsStringKey"
        static let addDataInstructions_showingFieldDetailsDefault: Bool = false
        
        static let statsFontSizeStringKey: String = "statsFontSizeStringKey"
        static let defaultStatsFontSize: CGFloat = 16.0
        static let maxStatsFontSize: CGFloat = 20.0
        static let minStatsFontSize: CGFloat = 12.0
        
    }
}
