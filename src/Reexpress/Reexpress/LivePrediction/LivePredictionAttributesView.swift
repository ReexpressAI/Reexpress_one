//
//  LivePredictionAttributesView.swift
//  Alpha1
//
//  Created by A on 9/11/23.
//

import SwiftUI

struct LivePredictionAttributesView: View {
    
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
        
    @Binding var liveDocumentState: LiveDocumentState
    
    @State private var isShowingAttributesView: Bool = false
    
    var attributes: [Float32] {
        return liveDocumentState.attributes

    }
    
    var body: some View {
        VStack {
            HStack {

                Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                    .foregroundStyle(Color.blue.gradient)
                Text(REConstants.PropertyDisplayLabel.attributesFull)
                    .font(.title3)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding([.leading, .trailing])
//            .popover(isPresented: $isShowingAttributesView) {
//                    LivePredictionAttributesAddView(liveDocumentState: $liveDocumentState)
//            }
            HStack(alignment: .top) {
                
                Text("Count: \(attributes.count)")
                            .monospaced()
                            .foregroundColor(.gray)
                            .font(REConstants.Fonts.baseFont)
                    Spacer()
            }
            .frame(minHeight: 20, maxHeight: 20)
            .padding()
            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false, viewBoxScaling: 4))
            .padding([.leading, .trailing])
        }
        .onTapGesture {
                isShowingAttributesView.toggle()
        }
        .sheet(isPresented: $isShowingAttributesView) {
            LivePredictionAttributesAddView(liveDocumentState: $liveDocumentState)
                .padding()
                .frame(
                 minWidth: 600, maxWidth: 800,
                 minHeight: 600, maxHeight: 600)
        }
        
    }
}



