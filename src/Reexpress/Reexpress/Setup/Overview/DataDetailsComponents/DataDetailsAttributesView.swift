//
//  DataDetailsAttributesView.swift
//  Alpha1
//
//  Created by A on 8/14/23.
//

import SwiftUI

struct DataDetailsAttributesView: View {
    
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
        
    @Binding var documentObject: Document?
    
    @State private var isShowingAttributesView: Bool = false
    
    var attributes: [Float32] {
        if let docObj = documentObject, let attributes = docObj.attributes?.vector?.toArray(type: Float32.self) {
            if attributes.count <= REConstants.KeyModelConstraints.attributesSize {
                return attributes
            }
        }
        return []
    }
    
    var body: some View {
        VStack {
            HStack {
//                Image(systemName: "rectangle.stack")
//                Image(systemName: "square.stack.3d.up")
                Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                    .foregroundStyle(attributes.count > 0 ? Color.blue.gradient : Color.gray.gradient)
                Text(REConstants.PropertyDisplayLabel.attributesFull)
                    .font(.title3)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding([.leading, .trailing])
            .popover(isPresented: $isShowingAttributesView) {
                if documentObject != nil, attributes.count > 0 {
                    AttributesView(documentObject: $documentObject)
                        //.frame(width: 450)
                }
            }
            HStack(alignment: .top) {
                
                if documentObject != nil {
                    
                    Text("Count: \(attributes.count)")
                            .monospaced()
                            .foregroundColor(.gray)
                            .font(REConstants.Fonts.baseFont)
                    Spacer()
                } else {
                    Text("")
                }
            }
            .frame(minHeight: 20, maxHeight: 20)
            .padding()
            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false, viewBoxScaling: 4))
            .padding([.leading, .trailing])
        }
        .onTapGesture {
            if documentObject != nil, attributes.count > 0 {
                isShowingAttributesView.toggle()
            }
        }
    }
}


