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

struct OfflineView: View {

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

    private let logger = Logger.swiftfin()

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 72))
                .foregroundColor(.secondary)

            Text("You're Offline")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No downloaded content available")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if networkMonitor.isConnected {
                Button {
                    // Force refresh when connection is restored
                    if let userSession = userSession {
                        Notifications[.didChangeCurrentServerURL].post(userSession.server)
                    } else {
                        // If no user session, go to sign in
                        Notifications[.didSignOut].post()
                    }
                } label: {
                    Label("Go Online", systemImage: "wifi")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Downloaded Content")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                Text("You can watch these items while offline")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                LazyVStack(spacing: 12) {
                    ForEach(downloadedItems) { downloadTask in
                        DownloadedItemRow(downloadTask: downloadTask)
                            .onTapGesture {
                                playDownloadedItem(downloadTask)
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Loading offline content...")
                            .foregroundColor(.secondary)
                    }
                } else if downloadedItems.isEmpty {
                    emptyView
                } else {
                    contentView
                }
            }
            .navigationTitle("Offline Downloads")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
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

                        // Debug button for troubleshooting
                        Button {
                            logger.info("Manual debug trigger requested")
                            downloadManager.debugDownloadsDirectory()
                        } label: {
                            Image(systemName: "ladybug")
                                .foregroundColor(.secondary)
                        }

                        if networkMonitor.isConnected {
                            Button {
                                // Force refresh to go back online
                                if let userSession = userSession {
                                    Notifications[.didChangeCurrentServerURL].post(userSession.server)
                                } else {
                                    // If no user session, go to sign in
                                    Notifications[.didSignOut].post()
                                }
                            } label: {
                                Label("Go Online", systemImage: "wifi")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            logger.info("OfflineView appeared")
            Task {
                loadDownloadedItems()
            }
        }
        .onReceive(networkMonitor.$isConnected) { isConnected in
            if isConnected {
                // Automatically try to go online when connection is restored
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if let userSession = userSession {
                        Notifications[.didChangeCurrentServerURL].post(userSession.server)
                    } else {
                        // If no user session, go to sign in
                        Notifications[.didSignOut].post()
                    }
                }
            }
        }
    }

    private func loadDownloadedItems() {
        logger.info("Loading downloaded items for offline mode")
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
}

struct DownloadedItemRow: View {
    let downloadTask: DownloadTask

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
    }
}
