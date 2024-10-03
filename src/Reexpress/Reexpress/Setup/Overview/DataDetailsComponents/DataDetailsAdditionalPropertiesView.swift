//
//  DataDetailsAdditionalPropertiesView.swift
//  Alpha1
//
//  Created by A on 8/14/23.
//

import SwiftUI

struct DataDetailsAdditionalPropertiesView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentObject: Document?
    
    @Binding var showingEditGroupFieldView: Bool
    @Binding var showingEditInfoFieldView: Bool
    var body: some View {
        Group {
            Spacer()
            HStack {
                Text("ID")
                    .font(.title3)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding([.leading, .trailing])
            
            ScrollView {
                if let docObj = documentObject {
                    VStack(alignment: .leading) {
                        Text(docObj.id ?? "")
                            .textSelection(.enabled)
                            .monospaced()
                            .font(REConstants.Fonts.baseFont)
                            .lineSpacing(12.0)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                } else {
                    Text("")
                }
            }
            .frame(minHeight: 20, maxHeight: 20)
            .padding()
            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false))
            .padding([.leading, .trailing])
        }
        
        Group {
            Spacer()
            HStack {
                Text("Group")
                    .font(.title3)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding([.leading, .trailing])
            HStack(alignment: .top) {
                if documentObject != nil {
                    Label("", systemImage: "rectangle.and.pencil.and.ellipsis")
                        .foregroundStyle(.blue.gradient)
                }
                
                ScrollView {
                    if let docObj = documentObject {
                        VStack(alignment: .leading) {
                            Text(docObj.group ?? "")
                                .textSelection(.enabled)
                                .monospaced()
                                .font(REConstants.Fonts.baseFont)
                                .lineSpacing(12.0)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        }
                    } else {
                        Text("")
                    }
                }
            }
            .frame(minHeight: 20, maxHeight: 20)
            .padding()
            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false))
            .padding([.leading, .trailing])
            .onTapGesture {
                if documentObject != nil {
                    showingEditGroupFieldView.toggle()
                }
            }
        }
        
        Group {
            Spacer()
            HStack {
                Text("Info")
                    .font(.title3)
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding([.leading, .trailing])
            
            HStack(alignment: .top) {
                if documentObject != nil {
                    Label("", systemImage: "rectangle.and.pencil.and.ellipsis")
                        .foregroundStyle(.blue.gradient)
                }
                ScrollView {
                    if let docObj = documentObject {
                        VStack(alignment: .leading) {
                            Text(docObj.info ?? "")
                                .textSelection(.enabled)
                                .monospaced()
                                .font(REConstants.Fonts.baseFont)
                                .lineSpacing(12.0)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        }
                    } else {
                        Text("")
                    }
                }
            }
            .frame(minHeight: 20, maxHeight: 20)
            .padding()
            .modifier(PrimaryComponentsViewModifier(useReBackgroundDarker: false))
            .padding([.leading, .trailing])
            .onTapGesture {
                if documentObject != nil {
                    showingEditInfoFieldView.toggle()
                }
            }
        }
        
        Group {
            VStack {
                HStack(alignment: .lastTextBaseline) {
                    Text("Date Added")
                        .font(.title3)
                        .foregroundStyle(.gray)
                    PopoverViewWithButtonLocalState(popoverViewText: REConstants.DataDetailsView.dateAdded)
                    Spacer()
                }
                .padding([.leading, .trailing])
                
                HStack(alignment: .top) {
                    
                    if let docObj = documentObject {
                        if let dateAdded = docObj.dateAdded {
                            Text(dateAdded, formatter: REConstants.dateFormatter)
                                .foregroundColor(.gray)
                                .font(REConstants.Fonts.baseFont)
                        } else {
                            Text("")
                                .foregroundColor(.gray)
                                .font(REConstants.Fonts.baseFont)
                        }
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
        }
    }
}
