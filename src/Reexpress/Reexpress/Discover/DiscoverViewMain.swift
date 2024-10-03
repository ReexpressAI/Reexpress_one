//
//  DiscoverViewMain.swift
//  Alpha1
//
//  Created by A on 8/30/23.
//

import SwiftUI

struct DiscoverViewMain: View {
    @EnvironmentObject var dataController: DataController
    @Binding var loadedDatasets: Bool
    @State private var showFeaturesView = true
    @State private var showPossibleErrorsView = false
    
    var body: some View {
        if loadedDatasets {
            VStack {
                VStack {
                    Grid {
                        GridRow {
                            
                            Grid(alignment: .center, verticalSpacing: 0) {
                                
                                GridRow {
                                    HStack(alignment: .lastTextBaseline) {
                                        Button {
                                            withAnimation {
                                                showFeaturesView = true
                                                showPossibleErrorsView = false
                                            }
                                        } label: {
                                            PrimaryHeaderControlButton(isSelected: $showFeaturesView, exclusiveSelection: true, buttonImageName: "chart.pie.fill", buttonTextCaption: "Features")
                                        }
                                        .buttonStyle(.borderless)
                                        
                                        
                                        Button {
                                            withAnimation {
                                                showFeaturesView = false
                                                showPossibleErrorsView = true
                                            }
                                        } label: {
                                            PrimaryHeaderControlButton(isSelected: $showPossibleErrorsView, exclusiveSelection: true, buttonImageName: "puzzlepiece.fill", buttonTextCaption: "Errors")
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }
                            }
                            .padding()
                            .modifier(SimpleBaseBorderModifierWithColorOption(useShadow: true))
//                            .background {
//                                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                    .fill(
//                                        AnyShapeStyle(BackgroundStyle()))
//                                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                    .stroke(.gray, lineWidth: 1)
//                                    .opacity(0.5)
//                            }
                            .gridColumnAlignment(.trailing)
                        }
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                
                ScrollView {
                    if showFeaturesView {
                        DiscoverViewFeatures() //(numberOfClasses: dataController.numberOfClasses)
                        .padding()
                        .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false, useShadow: true))
                        .padding()
                    } else {
                        DiscoverViewErrors() //numberOfClasses: dataController.numberOfClasses)
                        .padding()
                        .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false, useShadow: true))
                        .padding()
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }

    }
}
