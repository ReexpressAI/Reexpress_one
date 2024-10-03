//
//  SetupView.swift
//  Alpha1
//
//  Created by A on 6/24/23.
//

import SwiftUI

struct SetupView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var loadedDatasets: Bool
    @State private var showOverviewView = true
    //@State private var showDetailView = false
    @State private var showLabelsView = false
    
    var body: some View {
        VStack {
            ZStack {
                // MARK: Right column
                Grid {
                    GridRow {
                        
                        Grid(alignment: .center, verticalSpacing: 0) {
                            
                            GridRow {
                                HStack(alignment: .lastTextBaseline) {
                                    Button {
                                        withAnimation {
                                            showOverviewView = true
                                            //showDetailView = false
                                            showLabelsView = false
                                        }
                                    } label: {
                                        PrimaryHeaderControlButton(isSelected: $showOverviewView, exclusiveSelection: true, buttonImageName: "hexagon", buttonTextCaption: "Overview")
                                    }
                                    .buttonStyle(.borderless)
                                    
                                    /*Button {
                                     withAnimation {
                                     showOverviewView = false
                                     showDetailView = true
                                     showLabelsView = false
                                     }
                                     } label: {
                                     PrimaryHeaderControlButton(isSelected: $showDetailView, exclusiveSelection: true, buttonImageName: "circle.hexagongrid", buttonTextCaption: "Documents")
                                     }
                                     .buttonStyle(.borderless)*/
                                    
                                    Button {
                                        withAnimation {
                                            showOverviewView = false
                                            //showDetailView = false
                                            showLabelsView = true
                                        }
                                    } label: {
                                        PrimaryHeaderControlButton(isSelected: $showLabelsView, exclusiveSelection: true, buttonImageName: "target", buttonTextCaption: REConstants.MenuNames.labelsName)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                        .padding()
                        .modifier(SimpleBaseBorderModifierWithColorOption(useShadow: true))
//                        .background {
//                            RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                .fill(
//                                    AnyShapeStyle(BackgroundStyle()))
//                            RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                .stroke(.gray, lineWidth: 1)
//                                .opacity(0.5)
//                        }
                        .gridColumnAlignment(.trailing)
                    }
                }
            }
            .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
            
            if showOverviewView {
                DocumentCardViewEntryView(loadedDatasets: $loadedDatasets)
                /*} else if showDetailView {
                 DataOverviewView(numberOfClasses: dataController.numberOfClasses, loadedDatasets: $loadedDatasets)
                 .modifier(IntrospectViewPrimaryComponentsViewModifier())
                 }*/
            } else {
                LabelsOverviewView(loadedDatasets: $loadedDatasets)
                    .modifier(IntrospectViewPrimaryComponentsViewModifier(useShadow: true))
            }
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView(loadedDatasets: .constant(true))
    }
}
