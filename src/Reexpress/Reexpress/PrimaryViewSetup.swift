//
//  PrimaryViewSetup.swift
//  Alpha1
//
//  Created by A on 1/28/23.
//

import SwiftUI

struct PrimaryViewSetup: View {
    var projectDirectoryURL: URL?
    @StateObject var dataController: DataController  // This gets initialized below once the project url is available.

    init(projectDirectoryURL: URL?) {
        //print("BEGIN PrimaryViewSetup.swift init -- this should only be called once")
        self.projectDirectoryURL = projectDirectoryURL
        _dataController = StateObject(wrappedValue: DataController(projectURL: projectDirectoryURL))
        //print("END PrimaryViewSetup.swift init -- this should only be called once")
    }

    var body: some View {
        PrimaryView(projectDirectoryURL: projectDirectoryURL)
            .environment(\.managedObjectContext,
                          dataController.container.viewContext)
            .environmentObject(dataController)
    }
}

