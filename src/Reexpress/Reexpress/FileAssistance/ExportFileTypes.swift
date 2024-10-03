//
//  ExportFileTypes.swift
//  Alpha1
//
//  Created by A on 9/21/23.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct JSONLinesExportDatasetFile: FileDocument {
    static var readableContentTypes = [UTType.jsonlType]
    var jsonLinesString = ""

    init(jsonLinesExportString: String = "") {
        jsonLinesString = jsonLinesExportString
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            jsonLinesString = String(decoding: data, as: UTF8.self)
        }
    }

    // this will be called when the system wants to write our data to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(jsonLinesString.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
