//
//  MainEntryView2.swift
//  Alpha1
//
//  Created by A on 3/16/23.
//

import SwiftUI



struct MainEntryView: View {
    
    
    @StateObject private var viewModel = ViewModel()
    
    @State private var showingProjectDirectoryChooser = true
    @State private var showingProjectDirectoryChooserAnimate = true
    @State private var projectDirectoryChooserDismissedWithoutSelection = false
    private let errorViewScaling: CGFloat = 2
    
    @State private var routeToViewSetup = false
    
    func didDismissProjectDirectoryChooser() {
        withAnimation {
            showingProjectDirectoryChooserAnimate = false
        }
        // Handle the dismissing action.
        if viewModel.projectFileURL == nil {
            projectDirectoryChooserDismissedWithoutSelection = true
        } else {
            projectDirectoryChooserDismissedWithoutSelection = false
        }
        
        if !projectDirectoryChooserDismissedWithoutSelection && viewModel.projectFileURL != nil {
            routeToViewSetup = true
        }
        // Update the project name in sidebar
    }
//    @State private var presentingStoreKitSheet: Bool = false
//    @Environment(\.passStatus) private var passStatus
//    @Environment(\.passStatusIsLoading) private var passStatusIsLoading
//    @Environment(\.passIDs.group) private var passGroupID
    var body: some View {
        VStack{
            ZStack {
                GridPatternView()
                if projectDirectoryChooserDismissedWithoutSelection || viewModel.projectFileURL == nil {
                    ProjectOpenErrorView(showingProjectDirectoryChooser: $showingProjectDirectoryChooser)
                        .padding()
                        .modifier(IntrospectViewPrimaryComponentsViewModifier())
                        .frame(
                            minWidth: 800/errorViewScaling, maxWidth: 800/errorViewScaling,
                            minHeight: 600/errorViewScaling, maxHeight: 600/errorViewScaling)

                        .opacity( showingProjectDirectoryChooserAnimate ? 0 : 1 )
                    
                    
                }
                if routeToViewSetup {
                    PrimaryViewSetup(projectDirectoryURL: viewModel.projectFileURL)
                }
                
                
            }
            .sheet(isPresented: $showingProjectDirectoryChooser,
                   onDismiss: didDismissProjectDirectoryChooser) {
                ProjectDirectoryChooserModal(projectDirectoryURL: $viewModel.projectFileURL)
                    .frame(
                        minWidth: 800, maxWidth: 800,
                        minHeight: 600, maxHeight: 600)
            }
        }
//        .task {
//            await MainActor.run {
//                switch passStatus {
//                case .notSubscribed:
//                    presentingStoreKitSheet = true // also need to check for isLoading
//                case .fed_2023v1:
//                    break
//                }
//            }
//        }
//        .sheet(isPresented: $presentingStoreKitSheet) {
//            SubscriptionPassShop()
//        }
//        // temp to bypass -- Comment out the .onAppear for normal operation. With the .onAppear, upload a db with the string name and place it in the Documents folder (e.g., /Users/a/Library/Containers/com.reexpress.demo1.Alpha1/Data/Documents/sentimentEx1.re1) and then the app will skip the initial entry view.
        //Users/a/Library/Containers/express.re.Reexpress/Data/Documents/
       /*.onAppear {
           //print(Bundle.main.bundlePath)
//            let dbName = "SentimentTutorialUpdated.re1"
//           let dbName = "fastest.re1"
//           let dbName = "SentimentFaster.re1"
           let dbName = "SentimentFaster1withF.re1"
//            let dbName = "10class.re1"
//            let dbName = "Untitled.re1"
            viewModel.projectFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(dbName)
            
            
//            // estimate file size:
//            do {
//                let attribute = try FileManager.default.attributesOfItem(atPath: viewModel.projectFileURL?.path ?? "")
//                if let size = attribute[FileAttributeKey.size] as? NSNumber {
//                    let sizeInMB = size.doubleValue / 1000000.0
//                    print("Size of \(dbName): \(sizeInMB) MB")
//                }
//            } catch {
//
//            }
            
            showingProjectDirectoryChooser = false
            showingProjectDirectoryChooserAnimate = false
            projectDirectoryChooserDismissedWithoutSelection = false
            routeToViewSetup = true
        }*/
    }
}


extension MainEntryView {
    @MainActor class ViewModel: ObservableObject {
        @Published var projectFileURL: URL? = nil
    }
}



struct MainEntryView_Previews: PreviewProvider {
    static var previews: some View {
        MainEntryView()
    }
}
