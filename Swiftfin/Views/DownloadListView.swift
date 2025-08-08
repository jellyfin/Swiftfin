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

struct DownloadListView: View {

    // MARK: - State Properties

    @StateObject
    private var downloadManager = Container.shared.downloadManager()

    @State
    private var downloadedItems: [DownloadTask] = []

    @State
    private var isLoading = true

    @State
    private var showingDeleteAlert = false

    @State
    private var showingDeleteAllAlert = false

    @State
    private var taskToDelete: DownloadTask?

    // MARK: - Dependencies

    private let logger = Logger.swiftfin()

    // MARK: - Computed Properties

    private var totalStorageUsed: String {
        guard let totalBytes = downloadManager.getTotalDownloadSize() else {
            return L10n.unknown
        }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    // MARK: - Empty State View

    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)

            Text("No Downloads")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Download content to watch offline")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Storage summary header
                HStack {
                    Text("Downloaded content available for offline viewing")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if !downloadedItems.isEmpty {
                        Text("\(downloadedItems.count) items • \(totalStorageUsed)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal)

                // Downloads list
                LazyVStack(spacing: 12) {
                    ForEach(downloadedItems) { downloadTask in
                        DownloadItemRow(
                            downloadTask: downloadTask,
                            downloadManager: downloadManager,
                            onDelete: { deleteDownloadedItem(downloadTask) }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .refreshable {
            await refreshDownloads()
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Loading downloads...")
                            .foregroundStyle(.secondary)
                    }
                } else if downloadedItems.isEmpty {
                    emptyView
                } else {
                    contentView
                }
            }
            .navigationTitle(L10n.downloads)
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
                    if !downloadedItems.isEmpty {
                        Button {
                            logger.info("User requested to delete all downloads")
                            showingDeleteAllAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadDownloadedItems()
        }
    }

    // MARK: - Private Methods

    private func loadDownloadedItems() {
        logger.info("Loading downloaded items")

        let items = downloadManager.downloadedItems()
        logger.info("DownloadManager returned \(items.count) downloaded items")

        downloadedItems = items
        isLoading = false
        logger.info("Updated UI with \(items.count) downloaded items")
    }

    @MainActor
    private func refreshDownloads() async {
        logger.info("Pull-to-refresh triggered")
        loadDownloadedItems()
    }

    private func deleteDownloadedItem(_ downloadTask: DownloadTask) {
        logger.info("User requested to delete download: \(downloadTask.item.displayTitle)")
        taskToDelete = downloadTask
        showingDeleteAlert = true
    }

    private func confirmDelete() {
        guard let taskToDelete = taskToDelete,
              let itemId = taskToDelete.item.id else { return }

        logger.info("Confirming deletion of download: \(taskToDelete.item.displayTitle)")

        let success = downloadManager.deleteDownloadedMedia(itemId: itemId)

        if success {
            downloadedItems.removeAll { $0.item.id == itemId }
            logger.info("Successfully deleted download from UI")
        } else {
            logger.error("Failed to delete download for item: \(itemId)")
        }

        self.taskToDelete = nil
    }

    private func confirmDeleteAll() {
        logger.info("Confirming deletion of all downloads")
        downloadManager.deleteAllDownloadedMedia()
        downloadedItems.removeAll()
        logger.info("Successfully deleted all downloads from UI")
    }
}

// MARK: - Download Item Row

struct DownloadItemRow: View {

    // MARK: - Properties

    let downloadTask: DownloadTask
    let downloadManager: DownloadManager
    let onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ImageView(downloadManager.getImageURL(for: downloadTask, name: "Primary") ?? downloadManager
                .getImageURL(for: downloadTask, name: "Backdrop")
            )
            .failure {
                Rectangle()
                    .foregroundStyle(.secondary.opacity(0.3))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            .aspectRatio(contentMode: .fill)
            .frame(width: 80, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Content info
            VStack(alignment: .leading, spacing: 6) {
                Text(downloadTask.item.displayTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                if let overview = downloadTask.item.overview {
                    Text(overview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                // Metadata badges
                HStack {
                    if let year = downloadTask.item.productionYear {
                        Text(String(year))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    if let runtime = downloadTask.item.runTimeTicks {
                        let minutes = runtime / 600_000_000 // Convert ticks to minutes
                        Text("\(minutes)m")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Spacer()
                }

                Spacer()
            }

            Spacer()

            // Delete button
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.title2)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
