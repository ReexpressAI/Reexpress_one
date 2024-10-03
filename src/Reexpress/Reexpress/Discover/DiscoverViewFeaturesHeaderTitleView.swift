//
//  DiscoverViewFeaturesHeaderTitleView.swift
//  Alpha1
//
//  Created by A on 8/30/23.
//

import SwiftUI

struct DiscoverViewFeaturesHeaderTitleView: View {
    var headerTitle: String
    var onlyHighestReliability: Bool = false
    var headerTitleColor: Color = .orange
    //@Binding var statusSubtitle: String
    
    let buttonPadding = EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
    let buttonDividerHeight: CGFloat = 40
    var viewWidth: CGFloat = 450
    
    var highestReliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: 0, qCategory: .qMax, distanceCategory: .lessThanOrEqualToMedian, compositionCategory: .singleton), sizeOfCategory: REConstants.Uncertainty.minReliablePartitionSize)
    var highReliabilityLabel = UncertaintyStatistics.formatReliabilityLabel(dataPoint: nil, qdfCategory: UncertaintyStatistics.QDFCategory(prediction: 0, qCategory: .qMax, distanceCategory: .greaterThanMedianAndLessThanOrEqualToOOD, compositionCategory: .singleton), sizeOfCategory: REConstants.Uncertainty.minReliablePartitionSize)
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HStack(alignment: .center) {
                    Text(headerTitle) //Text("New document prediction")
                        .foregroundStyle(headerTitleColor)
                        .opacity(0.75)
                        .lineLimit(1)
                        .font(.system(size: 18))
                        .padding(buttonPadding)
                    Divider()
                        .frame(width: 2, height: buttonDividerHeight)
                        .overlay(.gray)
                    HStack {
                        Text("Selected from")
                            .lineLimit(1)
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                            //.italic()
                            .padding(buttonPadding)
                        
                        // Highest
                        Group {
                            VStack {
                                Image(systemName: highestReliabilityLabel.reliabilityImageName)
                                    .font(.title)
                                    .foregroundStyle(highestReliabilityLabel.reliabilityColorGradient)
                                    .opacity(highestReliabilityLabel.opacity)
                                Text(highestReliabilityLabel.reliabilityTextCaption)
                                    .foregroundStyle(.gray)
                                    .font(.title3)
                            }
                        }
                        if !onlyHighestReliability {
                            Text("and")
                                .lineLimit(1)
                                .foregroundColor(.gray)
                                .font(.system(size: 18))
                            //.italic()
                                .padding(buttonPadding)
                            // High
                            Group {
                                VStack {
                                    Image(systemName: highReliabilityLabel.reliabilityImageName)
                                        .font(.title)
                                        .foregroundStyle(highReliabilityLabel.reliabilityColorGradient)
                                        .opacity(highReliabilityLabel.opacity)
                                    Text(highReliabilityLabel.reliabilityTextCaption)
                                        .foregroundStyle(.gray)
                                        .font(.title3)
                                }
                            }
                        }
                        Text("calibration reliability partitions")
                            .lineLimit(1)
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                            //.italic()
                            .padding(buttonPadding)
//                        Text(statusSubtitle) //Text("Unsaved")
//                            .lineLimit(1)
//                            .foregroundColor(.gray)
//                            .font(.system(size: 18))
//                            .italic()
//                            .padding(buttonPadding)
                    }
                    Spacer()
                }
                .frame(width: viewWidth)
                Spacer()
            }
        }
        .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))
    }
}
