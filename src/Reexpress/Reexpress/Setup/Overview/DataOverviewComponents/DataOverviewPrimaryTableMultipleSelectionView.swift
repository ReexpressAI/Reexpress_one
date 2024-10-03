//
//  DataOverviewPrimaryTableMultipleSelectionView.swift
//  Alpha1
//
//  Created by A on 8/27/23.
//

import SwiftUI

struct TableDataPoint: Identifiable {
    let id: String
    let label: Int
    let prediction: Int
    let prompt: String
    let document: String
    
    let group: String
    let info: String
    
    let viewed: Bool
    let modified: Bool
}


struct DataOverviewPrimaryTableMultipleSelectionView: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var sortedDataPoints: [Document]
    @Binding var documentIdToIndex: [String: Int]
//    @Binding var selectedDocument: Document.ID?
    @Binding var multipleSelectedDocuments: Set<TableDataPoint.ID>
    var lineLimit: Int = 6
    
    @Binding var shouldScrollToTop: Bool
    @Binding var showingBatchSelectionView: Bool
//    @Binding var documentObject: Document?
    @AppStorage(REConstants.UserDefaults.documentTextOpacity) var documentTextOpacity: Double = REConstants.UserDefaults.documentTextDefaultOpacity
    var sortedTableDataPoints: [TableDataPoint] {
        // Document has an Optional ID, so we cannot use it for multiple selection in a Table. Instead, we create an in-memory object, TableDataPoint that mirrors the ManagedObject's properties.
        var dataPoints: [TableDataPoint] = []
        for documentObject in sortedDataPoints {
            if let documentID = documentObject.id {
                dataPoints.append(TableDataPoint(id: documentID, label: documentObject.label, prediction: documentObject.prediction, prompt: documentObject.prompt ?? "", document: documentObject.document ?? "", group: documentObject.group ?? "", info: documentObject.info ?? "", viewed: documentObject.viewed, modified: documentObject.modified))
            }
        }
        return dataPoints
    }
    
    /*func selectAll() {
        var fullSet = Set<TableDataPoint.ID>()
        for documentObject in sortedDataPoints {  // here we use the Document objects to avoid recreating sortedTableDataPoints
            if let documentID = documentObject.id {
                fullSet.insert(documentID)
            }
        }
        multipleSelectedDocuments = fullSet
    }*/
    @Binding var selectedDBRow: DatabaseRetrievalRow?
    func getGlobalRowIndex(relativeRowIndex: Int) -> Int {
        if let selectedRow = selectedDBRow {
            return selectedRow.startRow + relativeRowIndex
        }
        return relativeRowIndex
    }
    var body: some View {
        VStack {
            VStack {
//                HStack {
//                    Button {
//                        selectAll()
//                    } label: {
//                        HStack(alignment: .lastTextBaseline) {
//                            Image(systemName: sortedDataPoints.count == multipleSelectedDocuments.count ? "square.inset.filled" : "square")
//                                .foregroundStyle(.blue.gradient)
//                            Text("Select All")
//                        }
//                        .italic()
//                        .font(REConstants.Fonts.baseFont.smallCaps())
//                    }
//                    .buttonStyle(.borderless)
//                    PopoverViewWithButtonLocalState(popoverViewText: REConstants.HelpAssistanceInfo.selectionInfoString)
//                    Spacer()
//                }
                HStack {
                    PopoverViewWithButtonLocalState(popoverViewText: REConstants.HelpAssistanceInfo.selectionInfoString)
                    Spacer()
                }
                .padding([.leading, .trailing])
                Divider()
            }
            ScrollViewReader { (proxy: ScrollViewProxy) in
//                VStack {
//                    
//                }
//                .tag(424)
//                .id(424)
                Table(sortedTableDataPoints, selection: $multipleSelectedDocuments) { //$selectedDocument) {
//                    TableColumn("ID") { dataPoint in
//                        Text(dataPoint.id)
//                            .lineLimit(lineLimit...lineLimit)
//                    }
//                    .width(min: 60, ideal: 60)
                    TableColumn("ID") { dataPoint in
                        if let relativeRowIndex = documentIdToIndex[dataPoint.id] {
                            //Text("[\(relativeRowIndex)] \(dataPoint.id)")
                            Text("[\(getGlobalRowIndex(relativeRowIndex: relativeRowIndex))] \(dataPoint.id)")
                                .lineLimit(lineLimit...lineLimit)
                        } else {
                            Text(dataPoint.id)
                                .lineLimit(lineLimit...lineLimit)
                        }
                    }
                    .width(min: 70, ideal: 70)

                    TableColumn("Viewed") { dataPoint in
                        if dataPoint.viewed {
                            Text("Yes")
                                .lineLimit(lineLimit...lineLimit)
                        } else {
                            Text("No")
                                .lineLimit(lineLimit...lineLimit)
                        }
                    }
                    .width(min: 70, ideal: 70, max: 70)
                    TableColumn("Modified") { dataPoint in
                        if dataPoint.modified {
                            Text("Yes")
                                .lineLimit(lineLimit...lineLimit)
                        } else {
                            Text("No")
                                .lineLimit(lineLimit...lineLimit)
                        }
                    }
                    .width(min: 85, ideal: 85, max: 85)
                    TableColumn("Label") { dataPoint in
                        if let labelDisplayName = dataController.labelToName[dataPoint.label] {
                            Text(labelDisplayName)
                                .lineLimit(lineLimit...lineLimit)
                        } else {
                            Text("")
                                .lineLimit(lineLimit...lineLimit)
                        }
                    }
                    .width(min: 125, ideal: 125)
                    TableColumn("Prediction") { dataPoint in
                        if dataPoint.prediction >= 0, let labelDisplayName = dataController.labelToName[dataPoint.prediction] {
                            Text(labelDisplayName)
                                .lineLimit(lineLimit...lineLimit)
                        } else {
                            Text("N/A")
                                .lineLimit(lineLimit...lineLimit)
                        }
                    }
                    .width(min: 125, ideal: 125)
                    TableColumn("Prompt") { dataPoint in
                        Text(dataPoint.prompt)
                            .lineLimit(lineLimit...lineLimit)
                    }
                    .width(min: 100)

                    TableColumn("Document") { dataPoint in
                        Text(dataPoint.document)
                            .lineLimit(lineLimit...lineLimit)
                    }
                    .width(min: 500)
                    TableColumn("Group") { dataPoint in
                        Text(dataPoint.group)
                            .lineLimit(lineLimit...lineLimit)
                    }
                    .width(min: 200)
                    TableColumn("Info") { dataPoint in
                        Text(dataPoint.info)
                            .lineLimit(lineLimit...lineLimit)
                    }
                    .width(min: 200)
                }
                .monospaced()
                .opacity(documentTextOpacity)
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .font(REConstants.Fonts.baseFont)
                .onChange(of: shouldScrollToTop) { 
                    if let topDocument = sortedTableDataPoints.first {
                        proxy.scrollTo(topDocument.id, anchor: .topLeading)
                    }
                    shouldScrollToTop = false
                }
            }
        }
        .onDisappear {
            multipleSelectedDocuments.removeAll()
        }
    }
}
