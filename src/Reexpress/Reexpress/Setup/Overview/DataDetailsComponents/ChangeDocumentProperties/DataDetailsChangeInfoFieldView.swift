//
//  DataDetailsChangeInfoFieldView.swift
//  Alpha1
//
//  Created by A on 9/6/23.
//

import SwiftUI

struct DataDetailsChangeInfoFieldView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentObject: Document?
    
    @State var infoFieldText: String = ""
    @State var isShowingCoreDataSaveError: Bool = false
    
    func setCurrentInfoAsDefaultSelected() {
        if let docObject = documentObject {
            if let info = docObject.info {
                infoFieldText = info
            }
        }
    }
    var newInfoDiffersFromCurrentAndIsValidLength: Bool {
        guard let docObject = documentObject else {
            return false
        }
        if infoFieldText.count > REConstants.DataValidator.maxInfoRawCharacterLength {
            return false
        }
        if let info = docObject.info {
            return info != infoFieldText
        }
        return true
    }
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    HStack(spacing: 0) {
                        Text("Update the")
                            .font(REConstants.Fonts.baseFont)
                            .bold()
                        Text(" info ")
                            .font(REConstants.Fonts.baseFont)
                            .bold()
                            .foregroundColor(.gray)
                            .monospaced()
                        Text("field")
                            .font(REConstants.Fonts.baseFont)
                            .bold()
                    }
                    Spacer()
                }
                .padding(.bottom)
                
                HStack {
                    Spacer()
                    VStack {
                        
                        TextEditor(text: $infoFieldText)
                            .cornerRadius(12)
                            .padding()
                            .overlay(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.gray)
                                        .opacity(0.5)
                                }
                            )
                            .scrollContentBackground(.hidden)
                            .frame(width: 400, height: 150)
                            .modifier(CreateProjectViewControlViewModifier())
                        
                            .onChange(of: infoFieldText) {
                                // Ensure the text does not exceed the max length
                                if !infoFieldText.isEmpty {
                                    infoFieldText = String(infoFieldText.prefix(REConstants.DataValidator.maxInfoRawCharacterLength))
                                }
                            }
                        HStack {
                            Spacer()
                            Text("\(infoFieldText.count) / \(REConstants.DataValidator.maxInfoRawCharacterLength) characters")
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            setCurrentInfoAsDefaultSelected()
        }
        .alert(REConstants.GeneralErrors.coreDataSaveMessage, isPresented: $isShowingCoreDataSaveError) {
            Button("OK") {
                dismiss()
            }
        }
        
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .frame(width: 100)
                }
                .controlSize(.large)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    do {
                        if newInfoDiffersFromCurrentAndIsValidLength {
                            try dataController.updateInfoForOneDocument(documentObject: documentObject, newInfoFieldText: infoFieldText, moc: moc)
                            dismiss()
                        }
                    } catch {
                        isShowingCoreDataSaveError = true
                    }
                } label: {
                    Text("Update")
                        .frame(width: 100)
                }
                .controlSize(.large)
                .disabled(!newInfoDiffersFromCurrentAndIsValidLength)
                
            }
        }
    }
}
