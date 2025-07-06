//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import Logging

extension Container {
    var downloadDiagnostics: Factory<DownloadDiagnostics> { self { DownloadDiagnostics() }.shared }
}

class DownloadDiagnostics {

    // MARK: - Properties

    private let logger = Logger.swiftfin()

    // MARK: - Initialization

    fileprivate init() {
        logger.debug("Initializing DownloadDiagnostics")
    }

    /// Debug method to analyze the downloads directory structure and contents
    func debugDownloadsDirectory() {
        logger.info("=== DEBUGGING DOWNLOADS DIRECTORY ===")
        logger.info("Downloads path: \(URL.downloads.path)")

        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: URL.downloads.path, isDirectory: &isDirectory)
        logger.info("Directory exists: \(exists), isDirectory: \(isDirectory.boolValue)")

        if !exists {
            logger.warning("Downloads directory does not exist!")
            return
        }

        do {
            logger.info("--- Analyzing directory structure ---")
            analyzeDirectoryStructure(at: URL.downloads, depth: 0)

            logger.info("--- Testing downloadedItems() method ---")
            let downloadManager = Container.shared.downloadManager()
            let items = downloadManager.downloadedItems()
            logger.info("Found \(items.count) downloadable items")

            for (index, item) in items.enumerated() {
                logger.info("Item \(index + 1): \(item.item.displayTitle)")
                logger.info("  - ID: \(item.item.id ?? "nil")")
                logger.info("  - Type: \(item.item.type?.rawValue ?? "nil")")
                logger.info("  - Download folder: \(item.item.downloadFolder?.path ?? "nil")")

                if let mediaURL = item.getMediaURL() {
                    logger.info("  - Media file: \(mediaURL.lastPathComponent)")
                } else {
                    logger.warning("  - No media file found!")
                }
            }

        } catch {
            logger.error("Error analyzing downloads directory: \(error)")
        }

        logger.info("=== END DEBUGGING ===")
    }

    // MARK: - Directory Analysis

    /// Recursively analyze directory structure and log findings
    private func analyzeDirectoryStructure(at url: URL, depth: Int) {
        let indent = String(repeating: "  ", count: depth)

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: []
            )

            for item in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                let name = item.lastPathComponent

                if resourceValues.isDirectory == true {
                    logger.info("\(indent)📁 \(name)/")

                    // Check for special files in this directory
                    let metadataFile = item.appendingPathComponent("Metadata").appendingPathComponent("Item.json")
                    if FileManager.default.fileExists(atPath: metadataFile.path) {
                        logger.info("\(indent)  ✅ Contains Item.json metadata")
                    }

                    // Recursively analyze subdirectories (but limit depth to avoid infinite loops)
                    if depth < 5 {
                        analyzeDirectoryStructure(at: item, depth: depth + 1)
                    }
                } else {
                    let sizeString: String
                    if let fileSize = resourceValues.fileSize {
                        sizeString = " (\(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)))"
                    } else {
                        sizeString = ""
                    }
                    logger.info("\(indent)📄 \(name)\(sizeString)")
                }
            }
        } catch {
            logger.error("\(indent)❌ Error reading directory: \(error)")
        }
    }

    // MARK: - State Logging

    /// Debug method to log current download states from DownloadManager
    func logCurrentDownloadStates() {
        let downloadManager = Container.shared.downloadManager()

        logger.debug("=== CURRENT DOWNLOAD STATES ===")
        logger.debug("Total downloads: \(downloadManager.downloads.count)")
        logger.debug("Active downloads: \(downloadManager.activeDownloadCount)")

        for (index, download) in downloadManager.downloads.enumerated() {
            let stateDescription: String
            switch download.state {
            case .ready:
                stateDescription = "ready"
            case let .downloading(progress):
                stateDescription = "downloading (\(Int(progress * 100))%)"
            case .complete:
                stateDescription = "complete"
            case .cancelled:
                stateDescription = "cancelled"
            case let .error(error):
                stateDescription = "error: \(error.localizedDescription)"
            }

            logger.debug("Download \(index + 1): \(download.item.displayTitle) - \(stateDescription)")
        }

        logger.debug("Floating indicator should be visible: \(downloadManager.hasActiveDownloads)")
        logger.debug("=== END DOWNLOAD STATES ===")
    }
}
