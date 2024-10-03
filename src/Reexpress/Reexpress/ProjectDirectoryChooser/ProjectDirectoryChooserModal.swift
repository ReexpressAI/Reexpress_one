//
//  ProjectDirectoryChooserModal.swift
//  Alpha1
//
//  Created by A on 1/20/23.
//

import SwiftUI

enum ProjectSetupNavigationRoute: Int, CaseIterable {
    case taskSetupRoute = 0
    case modelSetupRoute = 1
    case promptSetupRoute = 2
    case fileSetupRoute = 3
}

struct ProjectSelectorLabelViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(
                minWidth: 325, maxWidth: 325,
                minHeight: 40, maxHeight: 40)
            .buttonStyle(.link)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        AnyShapeStyle(BackgroundStyle()))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.accentColor)
            }
        
    }
}

struct ProjectDirectoryChooserModal: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var initialSetupDataController: InitialSetupDataController
    
    @Binding var projectDirectoryURL: URL?
    @State private var selection: URL?
    
    @State private var projectDirModel = ProjectDirectoryCoordinator()
    
    @State private var proposalURL: URL?
    
    @State var infoPopoverShowing = false
    @State var historyPopoverShowing = false
    @State var newSelectionMade = false
    
    @State var historyWasCleared = false
    
    @State private var navPath = NavigationPath()
    @State private var showingProjectCreation = false
    @State private var currentPath: ProjectSetupNavigationRoute?
    
    
    var body: some View {
        
        NavigationStack(path: $navPath) {
            VStack {
                Spacer()
                VStack {
                    HStack(alignment: .lastTextBaseline) {
                        Text("Reexpress")
                            .font(Font.system(size: 46, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.orange.gradient)
                        
                        //Text("lite")
                        Text(REConstants.ProgramIdentifiers.mainProgramNameShort)
                            .font(Font.system(size: 22, weight: .thin))
                            .italic()
                            .foregroundStyle(.orange.gradient)
                        
                    }
                    .overlay(
                        Rectangle()
                            .fill(.orange.gradient
                                  //.shadow(.drop(color: Color.black, radius: 2, y: 3))
                                 )
                            .frame(height: 3).offset(y: 1.5),
                        alignment: .bottom)
                    .padding([.bottom], 10)
                    Text("Discover your data")
                        .font(Font.system(size: 22, weight: .bold))
                        .foregroundStyle(.gray)
                        .padding([.leading, .bottom, .trailing], 20)
                }
                .padding(40)
                .padding(.horizontal, 40)
                .modifier(SimpleBaseBorderModifier(useShadow: true))
                .padding()
                Spacer()
                VStack {
                    Grid(alignment: .center, verticalSpacing: 20) {
                        
                        GridRow {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 24.0))
                                .foregroundStyle(.blue.gradient)
                                .gridColumnAlignment(.trailing)
                            Text("Create a new project")
                                .font(.system(size: 20.0))
                                .foregroundStyle(.white)
                                .opacity(0.75)
                                .gridColumnAlignment(.leading)
                        }
                        .onTapGesture {
                            showingProjectCreation = true
                            navPath.append(ProjectSetupNavigationRoute.taskSetupRoute)
                            currentPath = ProjectSetupNavigationRoute.taskSetupRoute
                        }
                        GridRow {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 24.0))
                                .foregroundStyle(.blue.gradient)
                            Text("Open an existing project")
                                .font(.system(size: 20.0))
                                .foregroundStyle(.white)
                                .opacity(0.75)
                        }
                        .onTapGesture {
                            projectDirModel.promptAndGetDirectory()
                            withAnimation {
                                selection = projectDirModel.proposalURL
                            }
                        }
                        
                        /*GridRow {
                            Image(systemName: "clock")
                                .font(.system(size: 24.0))
                                .foregroundStyle(.blue.gradient)
                                .opacity((projectDirModel.recentURLs.count==0 || historyWasCleared) ? 0.25 : 1)
                            Text("Recent history")
                                .font(.system(size: 20.0))
                                .foregroundStyle(.white)
                                .opacity((projectDirModel.recentURLs.count==0 || historyWasCleared) ? 0.25 : 0.75)
                        }
                        .onTapGesture {
                            historyPopoverShowing = true
                        }
                        .sheet(isPresented: $historyPopoverShowing) {
                            HistoryView(selection: $selection, projectDirModel: $projectDirModel, historyWasCleared: $historyWasCleared)
                                .frame(
                                    minWidth: 400, maxWidth: 400,
                                    minHeight: 300, maxHeight: 300)
                        }*/
                    }
                }
                
//                VStack {
//                    Text("\(projectDirModel.proposalURL != nil ? projectDirModel.proposalURL!.description : " Select a file")")
//                }
                //Spacer()
                VStack {
                    if let proposalURL = projectDirModel.proposalURL { //}, newSelectionMade {
                        RecentProjectHistoryItem(
                            selection: $selection,
                            thisURL: proposalURL,
                            projectDirModel: $projectDirModel,
                            isHistory: false
                        )
                    } /*else {
                        EmptyRecentProjectHistoryItem()
                            .opacity(0.0)
                        
                    }*/
                }
                .frame(width: 350, height: 125)
                .padding()
                // NOTE: 2024-10-1: This will enable the 'View Subscription Store' and Account Status indicators. These are disabled in this version.
                //SubscriptionPassShopButtonView()
                
            }
            .navigationDestination(for: ProjectSetupNavigationRoute.self) { i in
                CreateProjectView1(projectFileModel: $projectDirModel, navigationPath: $navPath, navigationRoute: i)
                //                    .frame(
                //                        minWidth: 400, maxWidth: 400,
                //                        minHeight: 400, maxHeight: 400)
                    .frame(
                        minWidth: 400, maxWidth: .infinity,
                        minHeight: 400, maxHeight: .infinity)
                    .navigationTitle("Create a new project")
                    
//                    .navigationSubtitle("Subtitle")
//                    .navigationSubtitle("There's never been a better day to discover something remarkable.")
                
                
            }
            .toolbar(navPath.count == 0 ? .hidden : .visible, for: .windowToolbar)
            
        }
        .programControlStateInitializer()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    projectDirectoryURL = nil
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                if navPath.count == 0 {
                    Button("Continue") {
                        continueAction()
                        //dismiss()
                    }
                    .disabled(selection == nil)
                    .buttonStyle(.borderedProminent)
                } else {
                    
                    switch navPath.count {
                    case ProjectSetupNavigationRoute.taskSetupRoute.rawValue+1:
                        Button("Continue") {
                            navPath.append(ProjectSetupNavigationRoute.modelSetupRoute)
                        }
                    case ProjectSetupNavigationRoute.modelSetupRoute.rawValue+1:
                        Button("Continue") {
                            navPath.append(ProjectSetupNavigationRoute.promptSetupRoute)
                        }
                    case ProjectSetupNavigationRoute.promptSetupRoute.rawValue+1:
                        Button("Continue") {
                            navPath.append(ProjectSetupNavigationRoute.fileSetupRoute)
                        }
                    case ProjectSetupNavigationRoute.fileSetupRoute.rawValue+1:
                        Button("Create new project") {
                            continueAction(newProject: true)
                        }
                        .disabled(initialSetupDataController.projectURL == nil)
                    default:
                        Button("Continue") {
                        }
                        .disabled(true)
                    }
                    
                }
            }
        }
        .padding()
        //.frame(width: 600, height: 350)
        //.interactiveDismissDisabled(true) //(selection == nil)
    }
    
    var columns: [GridItem] {
        [ GridItem(.adaptive(minimum: 250)) ]
        //        [ GridItem(.fixed(250)) ]
    }
    
    func continueAction(newProject: Bool = false) {
        if newProject {
            if let url = initialSetupDataController.projectURL {
                //projectDirModel.updateRecentlyViewedURLS(newURL: url)
                projectDirectoryURL = url
                initialSetupDataController.isNewProject = true
            }
        } else {
            //experience = selection
            //projectDirModel.updateRecentlyViewedURLS(newURL: selection)
            projectDirectoryURL = selection
            initialSetupDataController.isNewProject = false
            // Mark: TODO: consolidate
            // Currently there is some duplication here with the data structures maintaining the project URL.
            initialSetupDataController.projectURL = projectDirectoryURL
        }
        dismiss()
    }
}
















