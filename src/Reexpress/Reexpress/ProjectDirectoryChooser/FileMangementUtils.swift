//
//  FileMangementUtils.swift
//  Alpha1
//
//  Created by A on 1/22/23.
//

import Foundation
import SwiftUI

class FileManagementUtils {
    static let shared: FileManagementUtils = {
        let instance = FileManagementUtils()
        // setup code
        return instance
    }()
    
    func showNSOpenPanelForSingleFileSelection()  -> URL? { //(allowedFileTypes: [String]? = nil) -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.resolvesAliases = false
        openPanel.allowsMultipleSelection = false
        openPanel.isAccessoryViewDisclosed = false
        openPanel.canCreateDirectories = false
        
        // TODO: https://developer.apple.com/documentation/uniformtypeidentifiers/defining_file_and_data_types_for_your_app
//        openPanel.allowedFileTypes = allowedFileTypes
        openPanel.allowsOtherFileTypes = false
        
        openPanel.allowedContentTypes = [.jsonlType]
        
        if (openPanel.runModal() ==  NSApplication.ModalResponse.OK) {
            return openPanel.urls.first

        } else {
            // Cancel option from user:
            return nil
        }
        
    }
    
}

