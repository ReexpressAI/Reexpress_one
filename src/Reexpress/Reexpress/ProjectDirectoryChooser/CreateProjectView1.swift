//
//  CreateProjectView1.swift
//  Alpha1
//
//  Created by A on 7/14/23.
//

/// Options menu for setting up a project

import SwiftUI

struct CreateProjectView1: View {
    
    
    @Binding var projectFileModel: ProjectDirectoryCoordinator
    @Binding var navigationPath: NavigationPath
    var navigationRoute: ProjectSetupNavigationRoute
    
    
    @State private var multiclassSelected = false
    @State private var showErrorCreatingFileAlert = false
    
    @EnvironmentObject var initialSetupDataController: InitialSetupDataController
    
    
    // temp
    //    @State var promptTopic: String = SentencepiecePrompts.getDefaultTopicOptions()[0]
    
    var body: some View {
        switch navigationRoute {
        case .taskSetupRoute:
            VStack {

                Text("It's a great day to discover something remarkable.")
                    .font(.title)
                
                    .italic()
                    .foregroundStyle(.orange.gradient)
                
                    .padding()
                .modifier(SimpleBaseBorderModifier(useShadow: true))
                .frame(width: 600)
                .padding()
                HStack {
                    Text("To get started, first select the number of unique class labels in your data.") //and choose a model.")
                        .font(.title)
                        .foregroundStyle(.gray)
                    Spacer()
                }
                .padding([.leading], 20)
                
                Spacer()
                VStack {
                    HStack {
                        
                        Form {
                            
                            Picker(selection: $initialSetupDataController.numberOfClasses) {
                                ForEach(2..<11, id: \.self) { numClasses in
                                    Text("\(numClasses)")
                                        .modifier(CreateProjectViewControlViewModifier())
                                        .tag(numClasses)
                                }
                            } label: {
                                Text("Number of classes:")
                                    .modifier(CreateProjectViewControlTitlesViewModifier())
                            }
                            .frame(minWidth: 200, maxWidth: 200, minHeight: 30, maxHeight: 30)
                            .padding([.bottom], 30)
                        }
                    }
                }
                Spacer()
                ProjectDetailsView(onlyShowTask: true)
                    .padding(.horizontal)
                
            }
        case .modelSetupRoute:
            VStack {
                HStack {
                    Text("Next, choose a model.")
                        .font(.title)
                        .foregroundStyle(.gray)
                    PopoverViewWithButtonLocalStateOptions(popoverViewText: "Keep in mind a larger model may take more time to process each document, but may require less training data to achieve similar effectiveness.", frameWidth: 350)
                        .font(REConstants.Fonts.baseFont)
                    Spacer()
                }
                .padding([.bottom, .vertical, .leading], 20)
                
                Spacer()
                ModelPickerView()
                Spacer()
                ProjectDetailsView()
                    .padding(.horizontal)
            }
        case .promptSetupRoute:
            VStack {
                HStack {
                    Text("Optionally, choose a default prompt.")
                        .font(.title)
                        .foregroundStyle(.gray)
                    PopoverViewWithButtonLocalStateOptions(popoverViewText: "This will be used as the prompt for any document uploaded without a **prompt** field in the JSON lines file.", optionalSubText: "If a **prompt** field is provided in the JSON lines file for a document and its value is the empty string, then no prompt will be used for that document, rather than this default prompt.", frameWidth: 350)
                        .font(REConstants.Fonts.baseFont)
                    Spacer()
                }
                .padding([.bottom, .vertical, .leading], 20)
                
                Spacer()
                
                Form {
                    
                    Picker(selection: $initialSetupDataController.defaultPromptOption.animation()) {
                        
                        Text(
                            DefaultPromptOption.getDefaultPromptOptionDescription(defaultPromptOption: DefaultPromptOption.template)
                        ).tag(DefaultPromptOption.template)
                            .modifier(CreateProjectViewControlViewModifier())
                        
                        Text(
                            DefaultPromptOption.getDefaultPromptOptionDescription(defaultPromptOption: DefaultPromptOption.custom)
                        ).tag(DefaultPromptOption.custom)
                            .modifier(CreateProjectViewControlViewModifier())
                        
                        Text(
                            DefaultPromptOption.getDefaultPromptOptionDescription(defaultPromptOption: DefaultPromptOption.none)
                        ).tag(DefaultPromptOption.none)
                            .modifier(CreateProjectViewControlViewModifier())
                        
                    } label: {
                        HStack {
                            Text("Default prompt type:")
                                .modifier(CreateProjectViewControlTitlesViewModifier())
                        }
                    }
                    .pickerStyle(.inline)
                    
                    Spacer()

                    switch initialSetupDataController.defaultPromptOption {
                    case .none:
                        PromptCustomView()
                            .hidden()
                    case .template:
//                        ZStack {
//                            PromptCustomView()
//                                .hidden()
//                            PromptTemplateView()
//                        }
                        PromptTemplateView()
                    case .custom:
                        PromptCustomView()
                    }
                }
                ProjectDetailsView()
                    .padding(.horizontal)
            }
        case .fileSetupRoute:
            VStack {
                HStack {
                    Text("Finally, select a location on your \(Text("Mac's internal hard drive").foregroundStyle(.reSemanticHighlight)) to store the project.")
                        .font(.title)
                        .foregroundStyle(.gray)
                    Spacer()
                }
                .padding([.bottom, .vertical, .leading], 20)
                Spacer()
                VStack {
                    HStack {
                        Button {
                            initialSetupDataController.projectURL = projectFileModel.showNSSavePanel()
                            do {
                                try initialSetupDataController.createFilePackageRootDirectoryAtProjectURL()
                            } catch {
                                showErrorCreatingFileAlert = true
                                // clear url
                                initialSetupDataController.projectURL = nil
                            }
                        } label: {
                            Text("Choose a directory and filename")
                        }
                        PopoverViewWithButtonLocalStateOptions(popoverViewText: "Project files must be stored on your Mac's internal hard drive when in use.", optionalSubText: "**\(REConstants.ProgramIdentifiers.mainProgramName)** utilizes the fast read/write speeds of your Mac's factory-provided hard drive(s). Saving/reading a **.re1** project file to/from an external or networked drive is not formally supported and may result in unexpected behavior.", frameWidth: 350)
                            .foregroundStyle(.reSemanticHighlight)
                            .font(REConstants.Fonts.baseFont)
                        /*Button {
                            storageInfoPopoverShowing.toggle()
                        } label: {
                            Image(systemName: "info.circle.fill")
                        }
                        .popover(isPresented: $storageInfoPopoverShowing, arrowEdge: .trailing) {
                            PopoverView(popoverViewText: "For the best performance, store the project file on your internal Mac hard drive. We recommend not using an external drive.")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.orange)*/
                    }
                    .padding()
                    .alert("We were unable to create the project file.", isPresented: $showErrorCreatingFileAlert) {
                        Button {
                        } label: {
                            Text("OK")
                        }
                    } message: {
                        Text("Please try again.")
                    }
                    
                    HStack {
                        Form {
                            LabeledContent {
                                if let url = initialSetupDataController.projectURL {
                                    Text("\(url.lastPathComponent)")
                                        .monospaced()
                                        .modifier(CreateProjectViewControlViewModifier())
                                        .lineLimit(4)
                                } else {
                                    Text("")
                                        .monospaced()
                                        .modifier(CreateProjectViewControlViewModifier())
                                }
                            } label: {
                                Text("Project name:")
                                    .modifier(CreateProjectViewControlTitlesViewModifier())
                            }
                            .padding()
                            
                            LabeledContent {
                                if let url = initialSetupDataController.projectURL {
                                    Text(projectFileModel.getProjectDirectoryStringFromURL(projectURL: url))
                                        .monospaced()
                                        .modifier(CreateProjectViewControlViewModifier())
                                        .lineLimit(4)
                                } else {
                                    Text("")
                                        .monospaced()
                                        .modifier(CreateProjectViewControlViewModifier())
                                }
                            } label: {
                                Text("Project directory:")
                                    .modifier(CreateProjectViewControlTitlesViewModifier())
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }
                Spacer()
                
                ProjectDetailsView()
                    .padding(.horizontal)
            }
        }
        Spacer()
        
    }
}
