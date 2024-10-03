//
//  REConstants+StarterCodeStrings.swift
//  Alpha1
//
//  Created by A on 9/22/23.
//

import Foundation

extension REConstants {
    struct StarterCodeString {
        // Note the extra \ in return [document0AsString, document1AsString].joined(separator:
        static let swiftStarterInputCode =
"""
import Foundation

struct JSONDocument: Codable, Identifiable {
    let id: String
    let label: Int
    var document: String
    let info: String?
    let attributes: [Float32]?
    var prompt: String?
    let group: String?
}
enum DocumentExportErrors: Error {
    case exportFailed
}
func exportJSONToStringLine(dataExportJSONDocument: JSONDocument) throws -> String {
    do{
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(dataExportJSONDocument)
        if let dataString = String(data: data, encoding: .utf8) {
            return dataString
        }
    } catch {
        throw DocumentExportErrors.exportFailed
    }
    throw DocumentExportErrors.exportFailed
}
func saveJSONLines(to filename: String, with datasplitAsString: String) throws {
    let url = URL(fileURLWithPath: filename)
    try datasplitAsString.write(to: url, atomically: true, encoding: String.Encoding.utf8)
}
func getDatasplitDocuments() throws -> String {
    let document0: JSONDocument = JSONDocument(id: UUID().uuidString, label: -1, document: "Example document 0", info: nil, attributes: nil, prompt: nil, group: nil)
    let document1: JSONDocument = JSONDocument(id: UUID().uuidString, label: -1, document: "Example document 1. Non-ascii characters can be used: 日本語", info: "placeholder text", attributes: [0.01, 0.02], prompt: "placeholder text", group: "placeholder text")
    
    let document0AsString = try exportJSONToStringLine(dataExportJSONDocument: document0)
    let document1AsString = try exportJSONToStringLine(dataExportJSONDocument: document1)
    
    return [document0AsString, document1AsString].joined(separator: "\\n")
}
func main() {
    let outputJSONLFile: String = CommandLine.arguments[1]
    do {
        let datasplitAsString: String = try getDatasplitDocuments()
        try saveJSONLines(to: outputJSONLFile, with: datasplitAsString)
        if !outputJSONLFile.hasSuffix(".jsonl") {
            print("Remember the file needs to have the ending .jsonl before it can be read into Reexpress one.")
        }
    } catch {
        print("Unable to save the example JSON lines file.")
    }
}

main()
"""
        // Note the extra \ in f.write(json.dumps(json_dict, ensure_ascii=True) + "
        static let pythonStarterInputCode =
"""
import argparse
import codecs
import json
import uuid

def get_documents():
    json_list = []
    json_list.append({"id": str(uuid.uuid4()), "label": -1,
                       "document": "Example document 0"})
    json_list.append({"id": str(uuid.uuid4()), "label": -1,
                      "prompt": "placeholder text",
                      "document": "Example document 1. Non-ascii characters can be used: 日本語",
                      "info": "placeholder text", "group": "placeholder text",
                      "attributes": [0.01, 0.02]})
    return json_list


def save_json_lines(filename_with_path, json_list):
    with codecs.open(filename_with_path, "w", encoding="utf-8") as f:
        for json_dict in json_list:
            f.write(json.dumps(json_dict, ensure_ascii=True) + "\\n")


def main():
    parser = argparse.ArgumentParser(
        description="-----[Output JSON lines format. Min starter code.]-----")
    parser.add_argument(
        "--output_jsonl_file", default="",
        help="JSON lines output file. Must have the ending .jsonl")

    options = parser.parse_args()
    json_list = get_documents()
    save_json_lines(options.output_jsonl_file, json_list)
    if not options.output_jsonl_file.endswith(".jsonl"):
        print("Remember the file needs to have the ending .jsonl before it can be read into Reexpress one.")


if __name__ == "__main__":
    main()
"""
    }
}
