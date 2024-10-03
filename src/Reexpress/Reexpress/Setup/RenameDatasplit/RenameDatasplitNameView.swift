//
//  RenameDatasplitNameView.swift
//  Alpha1
//
//  Created by A on 9/15/23.
//

import SwiftUI

struct RenameDatasplitNameView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    
    @Binding var userSpecifiedNameField: String
    @State private var nameBeforeChange: String = ""

    @State var isShowingCoreDataSaveError: Bool = false
    var datasetId: Int
    
    func recordOriginal() {
        nameBeforeChange = userSpecifiedNameField
    }
    var newDiffersFromCurrentAndIsValidLength: Bool {

        if userSpecifiedNameField.count > REConstants.Datasets.maxCharactersUserSpecifiedDatasetName {
            return false
        }
        return nameBeforeChange != userSpecifiedNameField && !isTraining && !isCalibration && !userSpecifiedNameField.isEmpty
    }
    
    var isTraining: Bool {
        return datasetId == REConstants.DatasetsEnum.train.rawValue
    }
    var isCalibration: Bool {
        return datasetId == REConstants.DatasetsEnum.calibration.rawValue
    }
    func validateAndAddNewDatasplitName(newName: String) {
        do {
            if newDiffersFromCurrentAndIsValidLength {
                try dataController.updateUserSpecifiedDatasetName(datasetIdInt: datasetId, newName: newName, moc: moc)
                dismiss()
            }
        } catch {
            revertDueToErrorOrCancellation()
            isShowingCoreDataSaveError = true
        }
    }
    func revertDueToErrorOrCancellation() {
        userSpecifiedNameField = nameBeforeChange
    }
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    HStack(spacing: 0) {
                        Text("Update the")
                            .font(REConstants.Fonts.baseFont)
                            .bold()
                        Text(" datasplit name ")
                            .font(REConstants.Fonts.baseFont)
                            .bold()
                            .foregroundColor(.gray)
                            .monospaced()
                    }
                    Spacer()
                }
                .padding(.bottom)
                
                HStack {
                    Spacer()
                    VStack {
                        
                        TextEditor(text: $userSpecifiedNameField)
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
                        
                            .onChange(of: userSpecifiedNameField) {
                                // Ensure the text does not exceed the max length
                                if !userSpecifiedNameField.isEmpty {
                                    userSpecifiedNameField = String(userSpecifiedNameField.prefix(REConstants.Datasets.maxCharactersUserSpecifiedDatasetName))
                                }
                            }
                        HStack {
                            Spacer()
                            Text("\(userSpecifiedNameField.count) / \(REConstants.Datasets.maxCharactersUserSpecifiedDatasetName) characters")
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            recordOriginal()
        }
        .alert(REConstants.GeneralErrors.coreDataSaveMessage, isPresented: $isShowingCoreDataSaveError) {
            Button("OK") {
                dismiss()
            }
        }
        
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    revertDueToErrorOrCancellation()
                    dismiss()
                } label: {
                    Text("Cancel")
                        .frame(width: 100)
                }
                .controlSize(.large)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    validateAndAddNewDatasplitName(newName: userSpecifiedNameField)
                } label: {
                    Text("Update")
                        .frame(width: 100)
                }
                .controlSize(.large)
                .disabled(!newDiffersFromCurrentAndIsValidLength)
                
            }
        }
    }
}
