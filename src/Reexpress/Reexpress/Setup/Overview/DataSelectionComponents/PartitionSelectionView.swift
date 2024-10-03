//
//  PartitionSelectionView.swift
//  Alpha1
//
//  Created by A on 8/16/23.
//

import SwiftUI


struct PartitionSelectionView: View {
    @EnvironmentObject var dataController: DataController

    @Binding var documentSelectionState: DocumentSelectionState
    
    enum PartitionSelectionViewType: Int, Hashable {
        case visual
        case table
    }
    @Binding var partitionSelectionViewType: PartitionSelectionViewType //= .table
    var body: some View {

//        ScrollView {
            VStack {
            VStack(alignment: .leading) {
                Text("Data Partitions")
                    .font(.title2.bold())
                VStack(alignment: .leading) {
                    Text("The calibrated probability is determined by the frequency of points within the same partition of the *Calibration Set*.")
                        .font(REConstants.Fonts.baseSubheadlineFont)
                        .foregroundStyle(.gray)
                    HStack(spacing: 0) {
                        Text("Select these partitions below for the following datasplit: ")
                            .font(REConstants.Fonts.baseSubheadlineFont)
                            .foregroundStyle(.gray)
                        SingleDatasplitView(datasetId: documentSelectionState.datasetId)
                            .monospaced()
                            .font(REConstants.Fonts.baseSubheadlineFont)
                    }
                }
                Divider()
                    //.padding(.bottom)
            }
            .padding([.leading, .trailing])


            HStack {
                Toggle(isOn: $documentSelectionState.includeAllPartitions) {
                    Text(REConstants.SelectionDisplayLabels.showAllPartitionsLabel)
                }
                .toggleStyle(.switch)
                Spacer()
            }
            .padding([.leading, .trailing, .top])
            .onChange(of: documentSelectionState.includeAllPartitions) {
                // To avoid confusing cases with partition size constraints being turned on and off, we simply always reset whenever this is enabled or disabled:
                documentSelectionState.partitionSizeConstraints = PartitionSizeConstraints()
            }
            VStack {
                VStack {
                    PredictionProbabilitySelectionView(documentSelectionState: $documentSelectionState)
                }
                VStack {
                    VStack(alignment: .leading) {
                        HStack(alignment: .lastTextBaseline) {
                            Text("Quick Partition")
                                .font(.title2)

                            PopoverViewWithButtonLocalState(popoverViewText: "Optionally, pre-populate the partition options by Calibration Reliability.", optionalSubText: "Note that overall Calibration Reliability is distinct from the Calibrated Probability itself.")
                            Spacer()
                        }
                        .frame(width: 450)
                        .padding([.leading, .trailing])
                        
                        QuickSelectionByCalibrationReliabilityView(documentSelectionState: $documentSelectionState)
                            .padding()
                            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: true, viewBoxScaling: 8, maxWidth: 450))
                            .padding([.leading, .trailing, .bottom])
                    }
                }
                
                VStack {
                    VStack(alignment: .leading) {
                        HStack(alignment: .lastTextBaseline) {
                            Text("Partition")
                                .font(.title2)
                            Spacer()
                        }
                        .frame(width: 450)
                        .padding([.leading, .trailing])
                    }
                }
                PartitionSizeSelectionView(documentSelectionState: $documentSelectionState)
                Picker(selection: $partitionSelectionViewType.animation()) {
                    Text("Visual").tag(PartitionSelectionViewType.visual)
                        .font(REConstants.Fonts.baseFont)
                    Text("Table").tag(PartitionSelectionViewType.table)
                        .font(REConstants.Fonts.baseFont)
                } label: {
                    Text("")
                }
                .pickerStyle(.segmented)
                .frame(width: 450)
                .padding([.leading, .trailing])
                switch partitionSelectionViewType {
                case .visual:
                    VisualPartitionSelection(documentSelectionState: $documentSelectionState)
                        .frame(height: 385)
                        .padding()
                case .table:
                    PredictedClassSelection(documentSelectionState: $documentSelectionState)
                    QSelectionView(documentSelectionState: $documentSelectionState)
                    DistanceSelectionView(documentSelectionState: $documentSelectionState)
                    CompositionSelectionView(documentSelectionState: $documentSelectionState)
                }
            }
            .disabled(documentSelectionState.includeAllPartitions)
            .opacity(documentSelectionState.includeAllPartitions ? 0.25 : 1.0)
        }
        .font(REConstants.Fonts.baseFont)
        .padding()
        .modifier(SimpleBaseBorderModifier())
        .padding()
    }
}
