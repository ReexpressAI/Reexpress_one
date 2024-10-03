//
//  LivePredictionView.swift
//  Alpha1
//
//  Created by A on 4/24/23.
//

import SwiftUI



struct LivePredictionView: View {
//    @EnvironmentObject var dataController: DataController
//    @Environment(\.managedObjectContext) var moc

    @Binding var loadedDatasets: Bool
    @State var predictionStatus: LivePredictionStatus = .noDocumentText
        
    
    @State var columns: [GridItem] =
    [GridItem(.flexible(minimum: 750, maximum: .infinity), spacing: 5)]
    
    
    var body: some View {
        VStack {

            ScrollView {
                LazyVGrid(columns: columns, spacing: 5) {
                    if loadedDatasets {
                        LivePredictionTextEntry(predictionStatus: $predictionStatus)
                            .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                            .modifier(IntrospectViewPrimaryComponentsViewModifier(useShadow: true))
                    }
                }
            }
            
        }
    }
}
