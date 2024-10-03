//
//  DataDetailsDatasplitView.swift
//  Alpha1
//
//  Created by A on 8/15/23.
//

import SwiftUI

struct DataDetailsDatasplitView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
        
    @Binding var documentObject: Document?
    @Binding var isShowingDatasplitTransferView: Bool
    var allowTransfers: Bool = true
    var body: some View {
        Group {
            Spacer()
            HStack {
                Text("Datasplit")
                    .font(.title3)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding([.leading, .trailing])
            
            ScrollView {
                if let docObj = documentObject, let datasetId = docObj.dataset?.id {
                    HStack(alignment: .top) {
                    Label("", systemImage: "slider.horizontal.3")
                            .foregroundStyle(allowTransfers ? Color.blue.gradient : Color.gray.gradient)
                        SingleDatasplitView(datasetId: datasetId)
                            //.foregroundStyle(.blue)
                            //.textSelection(.enabled)
                            .monospaced()
                            .font(REConstants.Fonts.baseFont)
                            .lineSpacing(12.0)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        Spacer()
                    }
                } else {
                    Text("")
                }
                
            }
            .frame(minHeight: 20, maxHeight: 20)
            .padding()
            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false))
            .padding([.leading, .trailing])
            .onTapGesture {
                if documentObject != nil && allowTransfers {
                    isShowingDatasplitTransferView = true
                }
            }
        }
    
    }
}
