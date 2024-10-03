//
//  DataDetailsChangeGroupFieldView.swift
//  Alpha1
//
//  Created by A on 9/6/23.
//

import SwiftUI

struct DataDetailsChangeGroupFieldView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var documentObject: Document?
    
    @State var groupFieldText: String = ""
    @State var isShowingCoreDataSaveError: Bool = false
    
    func setCurrentGroupAsDefaultSelected() {
        if let docObject = documentObject {
            if let group = docObject.group {
                groupFieldText = group
            }
        }
    }
    var newGroupDiffersFromCurrentAndIsValidLength: Bool {
        guard let docObject = documentObject else {
            return false
        }
        if groupFieldText.count > REConstants.DataValidator.maxGroupRawCharacterLength {
            return false
        }
        if let group = docObject.group {
            return group != groupFieldText
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
                        Text(" group ")
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
                        
                        TextEditor(text: $groupFieldText)
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
                        
                            .onChange(of: groupFieldText) { 
                                // Ensure the text does not exceed the max length
                                if !groupFieldText.isEmpty {
                                    groupFieldText = String(groupFieldText.prefix(REConstants.DataValidator.maxGroupRawCharacterLength))
                                }
                            }
                        HStack {
                            Spacer()
                            Text("\(groupFieldText.count) / \(REConstants.DataValidator.maxGroupRawCharacterLength) characters")
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            setCurrentGroupAsDefaultSelected()
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
                        if newGroupDiffersFromCurrentAndIsValidLength {
                            try dataController.updateGroupForOneDocument(documentObject: documentObject, newGroupFieldText: groupFieldText, moc: moc)
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
                .disabled(!newGroupDiffersFromCurrentAndIsValidLength)
                
            }
        }
    }
}
