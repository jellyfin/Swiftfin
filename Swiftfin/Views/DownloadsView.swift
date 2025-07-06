//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import Logging
import SwiftUI

struct DownloadsView: View {

    @Injected(\.downloadManager)
    private var downloadManager

    @Injected(\.networkMonitor)
    private var networkMonitor

    @Injected(\.currentUserSession)
    private var userSession

    @Router
    private var router

    @State
    private var downloadedItems: [DownloadTask] = []

    @State
    private var isLoading: Bool = true

    @State
    private var showingDeleteAlert = false

    @State
    private var showingDeleteAllAlert = false

    @State
    private var taskToDelete: DownloadTask?

    private let logger = Logger.swiftfin()

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 72))
                .foregroundColor(.secondary)

            Text("No Downloads")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Download content to watch offline")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if !networkMonitor.isConnected {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.orange)
                        Text("You're Offline")
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)

                    Text("Downloaded content will appear here when available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
    }

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {

                    Spacer()

                    if !networkMonitor.isConnected {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.orange)
                            Text("Offline")
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(6)
                    }
                }
                .padding(.horizontal)

                HStack {
                    Text(networkMonitor.isConnected ?
                        "Downloaded content available for offline viewing" :
                        "Offline content"
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    Spacer()

                    if !downloadedItems.isEmpty {
                        Text("\(downloadedItems.count) items • \(totalStorageUsed)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                LazyVStack(spacing: 12) {
                    ForEach(downloadedItems) { downloadTask in
                        let folderSize = downloadTask.item.downloadFolder.flatMap { calculateFolderSize(at: $0) }
                        DownloadedItemRow(
                            downloadTask: downloadTask,
                            folderSize: folderSize
                        ) {
                            playDownloadedItem(downloadTask)
                        } onDelete: {
                            deleteDownloadedItem(downloadTask)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .refreshable {
            logger.info("Pull-to-refresh triggered")
            await Task {
                loadDownloadedItems()
            }.value
        }
    }

    private var totalStorageUsed: String {
        var totalBytes: Int64 = 0

        for downloadTask in downloadedItems {
            if let downloadFolder = downloadTask.item.downloadFolder,
               let folderSize = calculateFolderSize(at: downloadFolder)
            {
                totalBytes += folderSize
            }
        }

        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    private func calculateFolderSize(at url: URL) -> Int64? {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        var totalSize: Int64 = 0

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            } catch {
                // Skip files that can't be read
                continue
            }
        }

        return totalSize > 0 ? totalSize : nil
    }

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Loading downloads...")
                            .foregroundColor(.secondary)
                    }
                } else if downloadedItems.isEmpty {
                    emptyView
                } else {
                    contentView
                }
            }
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete Download", isPresented: $showingDeleteAlert) {
                Button(L10n.cancel, role: .cancel) {
                    taskToDelete = nil
                }
                Button(L10n.delete, role: .destructive) {
                    confirmDelete()
                }
            } message: {
                if let taskToDelete = taskToDelete {
                    Text("Are you sure you want to delete '\(taskToDelete.item.displayTitle)'?")
                } else {
                    Text("Are you sure you want to delete this downloaded item?")
                }
            }
            .alert("Delete All Downloads", isPresented: $showingDeleteAllAlert) {
                Button(L10n.cancel, role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    confirmDeleteAll()
                }
            } message: {
                Text("Are you sure you want to delete all \(downloadedItems.count) downloaded items? This action cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // Delete All button (only show if there are downloads)
                        if !downloadedItems.isEmpty {
                            Button {
                                logger.info("User requested to delete all downloads")
                                showingDeleteAllAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }

                        // Refresh button
                        Button {
                            logger.info("Manual refresh triggered")
                            isLoading = true
                            Task {
                                loadDownloadedItems()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .onAppear {
            logger.info("DownloadsView appeared")
            Task {
                loadDownloadedItems()
            }
        }
    }

    private func loadDownloadedItems() {
        logger.info("Loading downloaded items")
        logger.debug("Network status: \(networkMonitor.isConnected)")
        logger.debug("User session available: \(userSession != nil)")
        logger.debug("Downloads directory path: \(URL.downloads.path)")

        // Run debugging analysis
        downloadManager.debugDownloadsDirectory()

        // Check if downloads directory exists
        var isDirectory: ObjCBool = false
        let downloadsExists = FileManager.default.fileExists(atPath: URL.downloads.path, isDirectory: &isDirectory)
        logger.debug("Downloads directory exists: \(downloadsExists), isDirectory: \(isDirectory.boolValue)")

        if downloadsExists {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: URL.downloads.path)
                logger.debug("Downloads directory contents: \(contents)")

                if contents.isEmpty {
                    logger.info("Downloads directory is empty")
                } else {
                    logger.info("Downloads directory contains \(contents.count) items: \(contents)")
                }
            } catch {
                logger.error("Failed to read downloads directory contents: \(error)")
            }
        } else {
            logger.warning("Downloads directory does not exist or is not a directory")
        }

        let items = downloadManager.downloadedItems()
        logger.info("DownloadManager returned \(items.count) downloaded items")

        for (index, item) in items.enumerated() {
            logger
                .debug(
                    "Item \(index): \(item.item.displayTitle) (ID: \(item.item.id ?? "nil")) - Type: \(item.item.type?.rawValue ?? "nil")"
                )

            // Check if media file exists for this item
            if let mediaURL = item.getMediaURL() {
                let mediaExists = FileManager.default.fileExists(atPath: mediaURL.path)
                logger.debug("  Media file exists: \(mediaExists) at \(mediaURL.path)")
            } else {
                logger.warning("  No media URL found for item")
            }

            // Check if images exist
            if let primaryImageURL = item.getImageURL(name: "Primary") {
                let imageExists = FileManager.default.fileExists(atPath: primaryImageURL.path)
                logger.debug("  Primary image exists: \(imageExists)")
            }

            if let backdropImageURL = item.getImageURL(name: "Backdrop") {
                let imageExists = FileManager.default.fileExists(atPath: backdropImageURL.path)
                logger.debug("  Backdrop image exists: \(imageExists)")
            }
        }

        DispatchQueue.main.async {
            self.downloadedItems = items
            self.isLoading = false
            self.logger.info("Updated UI with \(items.count) downloaded items")
        }
    }

    private func playDownloadedItem(_ downloadTask: DownloadTask) {
        let manager = DownloadVideoPlayerManager(downloadTask: downloadTask)

        router.route(to: .videoPlayer(manager: manager))
    }

    private func deleteDownloadedItem(_ downloadTask: DownloadTask) {
        logger.info("User requested to delete download: \(downloadTask.item.displayTitle)")
        taskToDelete = downloadTask
        showingDeleteAlert = true
    }

    private func confirmDelete() {
        guard let taskToDelete = taskToDelete else { return }

        logger.info("Confirming deletion of download: \(taskToDelete.item.displayTitle)")

        // Delete the download
        downloadManager.deleteDownload(task: taskToDelete)

        // Remove from UI list
        downloadedItems.removeAll { $0.item.id == taskToDelete.item.id }

        // Clear the task reference
        self.taskToDelete = nil

        logger.info("Successfully deleted download from UI")
    }

    private func confirmDeleteAll() {
        logger.info("Confirming deletion of all downloads")
        downloadManager.deleteAllDownloads()
        downloadedItems.removeAll()
        logger.info("Successfully deleted all downloads from UI")
    }
}

struct DownloadedItemRow: View {
    let downloadTask: DownloadTask
    let folderSize: Int64?
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ImageView(downloadTask.getImageURL(name: "Primary") ?? downloadTask.getImageURL(name: "Backdrop"))
                .failure {
                    Rectangle()
                        .foregroundColor(.secondary.opacity(0.3))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                }
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 60)
                .cornerRadius(8)
                .clipped()

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(downloadTask.item.displayTitle)
                    .font(.headline)
                    .lineLimit(1)

                if let overview = downloadTask.item.overview {
                    Text(overview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    if let runtime = downloadTask.item.runTimeLabel {
                        Label(runtime, systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // File size indicator
                    if let folderSize = folderSize {
                        Text(ByteCountFormatter.string(fromByteCount: folderSize, countStyle: .file))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Spacer()

                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(L10n.delete, systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Download", systemImage: "trash")
            }
        }
    }
}
