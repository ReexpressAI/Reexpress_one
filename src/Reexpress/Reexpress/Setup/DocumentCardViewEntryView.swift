//
//  Setup.swift
//  Alpha1
//
//  Created by A on 1/29/23.
//

import SwiftUI

struct DocumentCardViewEntryView: View {
    @Binding var loadedDatasets: Bool
    @EnvironmentObject var dataController: DataController
    
    
    var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: 300, maximum: 300),
                spacing: 20)
        ]
    }
    
    func shouldEmphasizeDataset(datasetId: Int) -> Bool {
        return datasetId == 0 || datasetId == 1
    }
    
    func datasetIsEmpty(dataset: InMemory_Dataset) -> Bool {
        return (dataset.count ?? 0) == 0
    }
    
    var body: some View {

        ScrollView {
            LazyVGrid(columns: columns, spacing: 15) {

                ForEach(Array(dataController.inMemory_Datasets.keys.sorted()), id: \.self) { datasetId in
                    if let dataset = dataController.inMemory_Datasets[datasetId] {
                        DocumentCardView(dataset: dataset)
                            .padding()

                            .frame(width: 300, height: 400) //, alignment: .topLeading)
                        
//                            .background {
//                                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                    .fill(BackgroundStyle())
//                                    .opacity(datasetIsEmpty(dataset: dataset) ? 0.5 : 1.0)
//                                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                    .stroke(.gray)
//                                    .opacity(0.5)
//                            }
//                            .background {
//                                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                    .fill(BackgroundStyle().shadow(.drop(color: .black, radius: 2, y: 3)))
//                                    .opacity(datasetIsEmpty(dataset: dataset) ? 0.5 : 1.0)
//                                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                    .stroke(.gray)
//                                    .opacity(0.5)
////                                Rectangle()
////                                    .fill(.black.shadow(.drop(color: .black, radius: 12)))
//                            }
                            .modifier(SimpleBaseBorderModifier(useShadow: true, opacity: datasetIsEmpty(dataset: dataset) ? 0.5 : 1.0))
                            .padding([.top, .bottom], 5)
                        
                    }
                }
            }
        }
        .padding(.vertical)
        .scrollBounceBehavior(.basedOnSize)
    }

}
