#!/usr/bin/env swift

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

// Helper function to recursively analyze directory structure
func analyzeDirectory(at path: String, depth: Int = 0) {
    let indent = String(repeating: "  ", count: depth)

    guard let enumerator = FileManager.default.enumerator(atPath: path) else {
        print("\(indent)❌ Cannot access directory: \(path)")
        return
    }

    var itemsAtThisLevel: [String] = []

    for case let item as String in enumerator {
        let itemPath = "\(path)/\(item)"
        var isDirectory: ObjCBool = false

        guard FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory) else {
            continue
        }

        // Only show direct children of current directory
        let components = item.components(separatedBy: "/")
        if components.count == 1 {
            itemsAtThisLevel.append(item)
        }
    }

    // Sort and display items
    itemsAtThisLevel.sort()

    for item in itemsAtThisLevel {
        let itemPath = "\(path)/\(item)"
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            print("\(indent)📁 \(item)/")

            // Check for special files
            let metadataPath = "\(itemPath)/Metadata/Item.json"
            if FileManager.default.fileExists(atPath: metadataPath) {
                print("\(indent)  ✅ Contains Item.json metadata")

                // Try to read and validate JSON
                if let data = FileManager.default.contents(atPath: metadataPath) {
                    print("\(indent)  📄 Metadata size: \(data.count) bytes")

                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        if let dict = json as? [String: Any] {
                            if let displayTitle = dict["displayTitle"] as? String {
                                print("\(indent)  📝 Title: \(displayTitle)")
                            }
                            if let itemType = dict["type"] as? String {
                                print("\(indent)  🏷️ Type: \(itemType)")
                            }
                            if let itemId = dict["id"] as? String {
                                print("\(indent)  🆔 ID: \(itemId)")
                            }
                        }
                    } catch {
                        print("\(indent)  ❌ Invalid JSON: \(error)")
                    }
                }
            }

            // Check for media files
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: itemPath)
                let mediaFiles = contents.filter { filename in
                    let ext = (filename as NSString).pathExtension.lowercased()
                    return ["mp4", "mkv", "avi", "mov", "m4v", "webm"].contains(ext) || filename.hasPrefix("Media")
                }

                for mediaFile in mediaFiles {
                    let filePath = "\(itemPath)/\(mediaFile)"
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath),
                       let fileSize = attributes[.size] as? Int64
                    {
                        let sizeString = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
                        print("\(indent)  🎬 \(mediaFile) (\(sizeString))")
                    } else {
                        print("\(indent)  🎬 \(mediaFile)")
                    }
                }
            } catch {
                print("\(indent)  ❌ Error reading contents: \(error)")
            }

            // Recursively analyze subdirectories (limit depth)
            if depth < 3 {
                analyzeDirectory(at: itemPath, depth: depth + 1)
            }
        } else {
            let filePath = "\(path)/\(item)"
            var sizeString = ""

            if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath),
               let fileSize = attributes[.size] as? Int64
            {
                sizeString = " (\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)))"
            }

            print("\(indent)📄 \(item)\(sizeString)")
        }
    }
}

// Main script
print("🔍 Swiftfin Downloads Directory Analyzer")
print(String(repeating: "=", count: 50))

// Get the simulator's documents directory path (you'll need to update this)
let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
let documentsPath = homeDirectory.appendingPathComponent("Documents").path

print("📂 Home directory: \(homeDirectory.path)")
print("📂 Documents directory: \(documentsPath)")

// Try to find the Swiftfin downloads directory
let possiblePaths = [
    "\(documentsPath)/Downloads",
    "\(homeDirectory.path)/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Documents/Downloads",
]

for path in possiblePaths {
    print("\n🔍 Checking: \(path)")

    if path.contains("*") {
        // This is a wildcard path, need to expand it
        let components = path.components(separatedBy: "/")
        if let devicesIndex = components.firstIndex(of: "*") {
            let basePath = components[0 ..< devicesIndex].joined(separator: "/")

            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: basePath)
                for device in contents {
                    let devicePath = "\(basePath)/\(device)"
                    let fullWildcardPath = path.replacingOccurrences(of: "*", with: device)

                    if FileManager.default.fileExists(atPath: fullWildcardPath) {
                        print("✅ Found downloads directory: \(fullWildcardPath)")
                        analyzeDirectory(at: fullWildcardPath)
                        break
                    }
                }
            } catch {
                print("❌ Cannot access: \(error)")
            }
        }
    } else if FileManager.default.fileExists(atPath: path) {
        print("✅ Found downloads directory!")
        analyzeDirectory(at: path)
    } else {
        print("❌ Directory not found")
    }
}

print("\n" + String(repeating: "=", count: 50))
print("🏁 Analysis complete!")
print("\nTo run this script:")
print("1. Save it as debug_downloads.swift")
print("2. Run: swift debug_downloads.swift")
print("3. Or copy the analyzeDirectory function into your app for debugging")
