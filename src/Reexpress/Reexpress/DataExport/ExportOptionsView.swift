//
//  ExportOptionsView.swift
//  Alpha1
//
//  Created by A on 9/21/23.
//

import SwiftUI

struct ExportOptionsView: View {
    @Binding var loadedDatasets: Bool
    @Binding var dataExportState: DataExportState
    
    var reliabilityLabel: (reliabilityImageName: String, reliabilityTextCaption: String, reliabilityColorGradient: AnyShapeStyle, opacity: Double) {
        return UncertaintyStatistics.formatReliabilityLabelFromQDFCategoryReliability(qdfCategoryReliability: .highestReliability)
    }
    
    var body: some View {
        if loadedDatasets {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text("Data Export")
                        .font(.title)
                        .foregroundStyle(.gray)
                    Spacer()
                    HelpAssistanceView_DataExport()
                }
                Spacer()
                ScrollView {
                    VStack {
                        HStack {
                            DatasplitSelectorViewSelectionRequired(selectedDatasetId: $dataExportState.datasetId, showLabelTitle: true)
                            Spacer()
                        }
                        HStack {
                            Form {
                                HStack(alignment: .center) {
                                    Toggle("", isOn: $dataExportState.id)
                                        .toggleStyle(.checkbox)
                                        .disabled(true)
                                    Text("id (required)")
                                    Spacer()
                                }
                                
                                HStack(alignment: .center) {
                                    Toggle("", isOn: $dataExportState.label)
                                        .toggleStyle(.checkbox)
                                    Text("label")
                                    Spacer()
                                }
                                HStack(alignment: .center) {
                                    Toggle("", isOn: $dataExportState.prompt)
                                        .toggleStyle(.checkbox)
                                    Text("prompt")
                                    Spacer()
                                }
                                HStack(alignment: .center) {
                                    Toggle("", isOn: $dataExportState.document)
                                        .toggleStyle(.checkbox)
                                    Text("document")
                                    Spacer()
                                }
                                
                                HStack(alignment: .center) {
                                    Toggle("", isOn: $dataExportState.info)
                                        .toggleStyle(.checkbox)
                                    Text("info")
                                    Spacer()
                                }
                                HStack(alignment: .center) {
                                    Toggle("", isOn: $dataExportState.group)
                                        .toggleStyle(.checkbox)
                                    Text("group")
                                    Spacer()
                                }
                                
                                HStack(alignment: .center) {
                                    Toggle("", isOn: $dataExportState.attributes)
                                        .toggleStyle(.checkbox)
                                    Text(REConstants.PropertyDisplayLabel.attributesFull)
                                    Spacer()
                                }
                                
                                
                                HStack(alignment: .center) {
                                    Toggle("", isOn: $dataExportState.prediction)
                                        .toggleStyle(.checkbox)
                                    Text("prediction")
                                    Spacer()
                                }
                                HStack(alignment: .center) {
                                    Toggle("", isOn: $dataExportState.probability)
                                        .toggleStyle(.checkbox)
                                    HStack(spacing: 0) {
                                        Text("probability for ")
                                        HStack(spacing: 0) {
                                            Image(systemName: reliabilityLabel.reliabilityImageName)
                                            Text(reliabilityLabel.reliabilityTextCaption)
                                                .modifier(CategoryLabelViewModifier())
                                        }
                                        .foregroundStyle(reliabilityLabel.reliabilityColorGradient.opacity(reliabilityLabel.opacity))
                                        Text(" Calibration Reliability predictions")
                                    }
                                    PopoverViewWithButtonLocalStateOptionsLocalizedString(popoverViewText: "The **probability** field is omitted for all other predictions in the exported file.")
                                    Spacer()
                                }
                            }
                            Spacer()
                        }
                        .padding()
                    }
                    
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            
            .padding()
            .modifier(SimpleBaseBorderModifier())
            .padding()
        }
    }
}
