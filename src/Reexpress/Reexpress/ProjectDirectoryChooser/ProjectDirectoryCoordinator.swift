//
//  ProjectDirectoryCoordinator.swift
//  Alpha1
//
//  Created by A on 1/22/23.
//

import Foundation
import SwiftUI

struct ProjectDirectoryCoordinator {
    
    //@AppStorage("recentURLs") var recentURLs = [URL]()
    var proposalURL: URL?
    var proposalURLIsUnique = false
    
    
    /*mutating func checkIfNewURLInHistory(userSelectedURL: URL) -> Bool {
        
        if recentURLs.contains(userSelectedURL) {
            // update history in order to get suitable file permissions
            if let index = recentURLs.firstIndex(of: userSelectedURL) {
                recentURLs.remove(at: index)
            }
            return true
        }
        return false
    }*/
    
    /*mutating func promptUserForDirectory() {
        if let userSelectedURL = showNSOpenPanel() {
            // check if the new URL is in the history, if so, no new proposalURL
//            if checkIfNewURLInHistory(userSelectedURL: userSelectedURL) {
//                proposalURL = nil
//            } else {
                proposalURL = userSelectedURL
           // }
            
        }
    }*/
  
    
    mutating func promptAndGetDirectory(initialDirectoryUrl: URL? = nil) {

        if let userSelectedURL = showNSOpenPanel(initialDirectoryUrl: initialDirectoryUrl) {
            proposalURL = userSelectedURL
        } else {
            proposalURL = nil
        }
    }
        
    func showNSOpenPanel(initialDirectoryUrl: URL? = nil) -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.resolvesAliases = false
        openPanel.allowsMultipleSelection = false
        openPanel.isAccessoryViewDisclosed = false
        openPanel.canCreateDirectories = true

        openPanel.allowedContentTypes = [.re1ProjectType]
        openPanel.allowsOtherFileTypes = false
        openPanel.isExtensionHidden = false
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.showsHiddenFiles = false

        if let url = initialDirectoryUrl {
            openPanel.directoryURL = url.deletingLastPathComponent()
        }

        if (openPanel.runModal() ==  NSApplication.ModalResponse.OK) {
            return openPanel.urls.first
        } else {
            // Cancel option from user:
            return nil
        }
    }
    
//    mutating func updateRecentlyViewedURLS(newURL: URL?) {
//        if let selectedURL = newURL, !recentURLs.contains(selectedURL) {
//            while recentURLs.count >= 4 {
//                recentURLs.removeLast()
//            }
//            recentURLs.insert(selectedURL, at: 0)
//        }
//        
//    }
    
    mutating func promptAndSaveProjectFile() {
        if let userSelectedURL = showNSSavePanel() {
            proposalURL = userSelectedURL
        } else {
            proposalURL = nil
        }
    }
    
    
    func showNSSavePanel() -> URL? {
        let savePanel = NSSavePanel()
        
        savePanel.title = "Create a new project"
        savePanel.message = "Choose a directory (on your Mac hard drive) and a name to store your project."
        savePanel.nameFieldLabel = "Project name:"
        
        savePanel.isExtensionHidden = false
        savePanel.canCreateDirectories = true
        
        savePanel.allowedContentTypes = [.re1ProjectType]
        savePanel.allowsOtherFileTypes = false
        savePanel.treatsFilePackagesAsDirectories = false
        savePanel.showsTagField = false
        
                
        if (savePanel.runModal() ==  NSApplication.ModalResponse.OK) {
            return savePanel.url
        } else {
            // Cancel option from user:
            return nil
        }
    }
    
    func getProjectDirectoryStringFromURL(projectURL: URL?) -> String {
        var projectDirectoryString = ""
        if let url = projectURL {
            var urlComponents = url.pathComponents
            if urlComponents.count > 1 {
                urlComponents.removeLast()
                projectDirectoryString = urlComponents.last ?? ""
            }
        }
        return projectDirectoryString
    }
    
}


