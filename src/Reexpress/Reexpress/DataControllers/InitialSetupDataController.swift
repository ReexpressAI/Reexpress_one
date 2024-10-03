//
//  InitialSetupDataController.swift
//  Alpha1
//
//  Created by A on 3/18/23.
//

import Foundation

enum ModelTask: Int, CaseIterable {
    case binaryClassification = 1
    case multiclassClassification = 2
    case qaClassification = 3
    
    func stringValue(numberOfClasses: Int? = nil) -> String {
        switch(self) {
        case .binaryClassification:
            return "Binary classification (+search+reranking)"
        case .multiclassClassification:
            if let numberOfClasses = numberOfClasses {
                return "\(numberOfClasses)-class classification (+search+reranking)"
            } else {
                return "Multiclass (> 2 classes) classification (+search+reranking)" //"Multiclass (> 2 classes) classification *(experimental)*"
            }
        case .qaClassification:
            return "QA Classification"
        }
    }
}

enum DefaultPromptOption: Int, CaseIterable {
    case template
    case custom
    case none
    
    static func getDefaultPromptOptionDescription(defaultPromptOption: DefaultPromptOption) -> String {
        switch defaultPromptOption {
        case .template:
            return "Template"
        case .custom:
            return "Custom"
        case .none:
            return "None"
        }
    }
}

class InitialSetupDataController: ObservableObject {
    
    @Published var modelTaskType: ModelTask = .binaryClassification
    @Published var numberOfClasses: Int = 2
    @Published var modelGroup: SentencepieceConstants.ModelGroup = .Faster
    @Published var projectURL: URL?
    @Published var isNewProject = false
    
    @Published var defaultPrompt: String = ""
    @Published var defaultPromptOption: DefaultPromptOption = .none
    @Published var defaultPromptTopic: String = SentencepiecePrompts.getDefaultTopicOptions()[0]
    @Published var defaultPromptDocumentType: String = SentencepiecePrompts.getDefaultDocumentTypeOptions()[0]
    
    func getConstructedPrompt() -> String {
        switch defaultPromptOption {
        case .template:
            return SentencepiecePrompts.getDefaultPromptWithOptions(topic: defaultPromptTopic, documentType: defaultPromptDocumentType)
        case .custom:
            return defaultPrompt
        case .none:
            return ""
        }
    }
    /// Destructive (overwritting) creation of the root directory of the project package. This is used if a user chooses an existing project file when in the "create a new project" menu. Without this, the existing database at the url would be loaded.
    func createFilePackageRootDirectoryAtProjectURL() throws {
        let fm = FileManager()
        if let url = projectURL {
            try? fm.removeItem(at: url)
            do {
                try fm.createDirectory(at: url, withIntermediateDirectories: false)
            } catch {
                throw GeneralFileErrors.unableToCreateProjectFile
            }
        } else {
            throw GeneralFileErrors.projectDirURLIsNil
        }
    }    
}
