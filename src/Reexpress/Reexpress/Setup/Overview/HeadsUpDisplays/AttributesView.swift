//
//  AttributesView.swift
//  Alpha1
//
//  Created by A on 8/14/23.
//

import SwiftUI

struct AttributesWithIndex: Identifiable {
    var id: Int {
        return index
    }
    let index: Int
    let attributeValue: Float32
    var indexAsString: String { String(index) }
    var attributeValueAsString: String { String(attributeValue) }
}

struct AttributesView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentObject: Document?
        
    var attributesWithIndex: [AttributesWithIndex] {
        if let docObj = documentObject, let attributes = docObj.attributes?.vector?.toArray(type: Float32.self) {
            if attributes.count <= REConstants.KeyModelConstraints.attributesSize {
                var data: [AttributesWithIndex] = []
                for attributeIndex in 0..<attributes.count {
                    data.append(.init(index: attributeIndex, attributeValue: attributes[attributeIndex]))
                }
                return data
            }
        }
        return []
    }
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text(REConstants.PropertyDisplayLabel.attributesFull)
                        .font(REConstants.Fonts.baseFont)
                        //.font(.title)
                        .bold()
//                        .foregroundStyle(.gray)
                    Spacer()
                    SimpleCloseButton()
                }
                .padding(.bottom)
//                .padding([.leading, .trailing, .bottom])
                HStack {
                    HStack {
                        Spacer()
                        Text("Index")
                            .foregroundStyle(.gray)
                    }
                        .frame(width: 100)
                        .padding([.leading, .trailing])
                    HStack {
                        Text("Value")
                        Spacer()
                    }
                        .frame(width: 200)
                        .padding([.leading, .trailing])
                    Spacer()
                }
                .font(REConstants.Fonts.baseFont)
                .monospaced()
                .padding([.leading, .trailing])
                Divider()
                List {
                    ForEach(attributesWithIndex) { index in
                        HStack {
                            HStack {
                                Spacer()
                                Text(index.indexAsString)
                                    .foregroundStyle(.gray)
                            }
                            .frame(width: 100)
                            .padding([.leading, .trailing])

                            HStack {
                                Text(index.attributeValueAsString)
                                Spacer()
                            }
                            .frame(width: 200)
                            .padding([.leading, .trailing])
                            Spacer()
                        }
                        
                        .font(REConstants.Fonts.baseFont)
                        .monospaced()
                    }
                }
                .frame(height: 350)
                .listStyle(.inset(alternatesRowBackgrounds: true))

            }
            .padding()
            .modifier(SimpleBaseBorderModifier())
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        //.padding([.leading, .trailing])
//        .modifier(SimpleBaseBorderModifier())
//        .padding()
    }
}

