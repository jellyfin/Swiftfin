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

    @Injected(\.downloadDiagnostics)
    private var downloadDiagnostics

    @Injected(\.networkMonitor)
    private var networkMonitor

    @Injected(\.currentUserSession)
    private var userSession

    @Router
    private var router

    @State
    private var downloadedItems: [DownloadTask] = []

    @State
    private var hierarchicalGroups: [DownloadGroup] = []

    @State
    private var isLoading: Bool = true

    @State
    private var showingDeleteAlert = false

    @State
    private var showingDeleteAllAlert = false

    @State
    private var taskToDelete: DownloadTask?

    @State
    private var isServerUnreachable: Bool = false

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
                OfflineBanner(type: .offline, showDescription: true)
            } else if isServerUnreachable {
                OfflineBanner(type: .serverUnreachable, showDescription: true)
            }
        }
        .padding()
    }

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {

                    Spacer()

                    if isServerUnreachable {
                        OfflineBanner(type: .serverUnreachable, compact: true)
                    } else if !networkMonitor.isConnected {
                        OfflineBanner(type: .offline, compact: true)
                    }
                }
                .padding(.horizontal)

                HStack {
                    Text(isServerUnreachable ?
                        "Your Jellyfin server is unreachable. Downloaded content is available for offline viewing." :
                        networkMonitor.isConnected ?
                        "Downloaded content available for offline viewing" :
                        "Offline content"
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    Spacer()

                    if !hierarchicalGroups.isEmpty {
                        Text("\(totalItemCount) items • \(totalStorageUsed)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                DownloadsHierarchicalView(
                    downloadGroups: hierarchicalGroups,
                    onPlayItem: playDownloadedItem,
                    onDeleteItem: deleteDownloadedItem
                )
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
        let totalBytes = hierarchicalGroups.reduce(0) { $0 + $1.totalStorageSize }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    private var totalItemCount: Int {
        hierarchicalGroups.reduce(0) { $0 + $1.itemCount }
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
                } else if hierarchicalGroups.isEmpty {
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
                Text("Are you sure you want to delete all \(totalItemCount) downloaded items? This action cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // Delete All button (only show if there are downloads)
                        if !hierarchicalGroups.isEmpty {
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
        .onNotification(.didDetectServerUnreachable) {
            logger.info("Server unreachable notification received in DownloadsView")
            isServerUnreachable = true
        }
        .onReceive(networkMonitor.$isConnected) { isConnected in
            // Reset server unreachable status when network status changes
            if isConnected {
                isServerUnreachable = false
            }
        }
    }

    private func loadDownloadedItems() {
        logger.info("Loading downloaded items")
        logger.debug("Network status: \(networkMonitor.isConnected)")
        logger.debug("User session available: \(userSession != nil)")
        logger.debug("Downloads directory path: \(URL.downloads.path)")

        // Run debugging analysis
        downloadDiagnostics.debugDownloadsDirectory()

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
            self.hierarchicalGroups = transformDownloadsToHierarchy(items)
            self.isLoading = false
            self.logger.info("Updated UI with \(items.count) downloaded items in \(self.hierarchicalGroups.count) groups")
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

        // Refresh hierarchical groups
        hierarchicalGroups = transformDownloadsToHierarchy(downloadedItems)

        // Clear the task reference
        self.taskToDelete = nil

        logger.info("Successfully deleted download from UI")
    }

    private func confirmDeleteAll() {
        logger.info("Confirming deletion of all downloads")
        downloadManager.deleteAllDownloads()
        downloadedItems.removeAll()
        hierarchicalGroups.removeAll()
        logger.info("Successfully deleted all downloads from UI")
    }
}
