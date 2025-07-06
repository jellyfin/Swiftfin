//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// MARK: - Hierarchical Downloads View Components

struct DownloadsHierarchicalView: View {
    let downloadGroups: [DownloadGroup]
    let onPlayItem: (DownloadTask) -> Void
    let onDeleteItem: (DownloadTask) -> Void

    @State
    private var expandedSeries: Set<String> = []
    @State
    private var expandedSeasons: Set<String> = []

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(downloadGroups) { group in
                DownloadGroupRow(
                    group: group,
                    expandedSeries: $expandedSeries,
                    expandedSeasons: $expandedSeasons,
                    onPlayItem: onPlayItem,
                    onDeleteItem: onDeleteItem
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Download Group Row

struct DownloadGroupRow: View {
    let group: DownloadGroup
    @Binding
    var expandedSeries: Set<String>
    @Binding
    var expandedSeasons: Set<String>
    let onPlayItem: (DownloadTask) -> Void
    let onDeleteItem: (DownloadTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch group {
            case let .movie(task):
                DownloadItemRow(
                    downloadTask: task,
                    folderSize: group.totalStorageSize,
                    onTap: { onPlayItem(task) },
                    onDelete: { onDeleteItem(task) }
                )

            case let .series(seriesGroup):
                SeriesGroupRow(
                    seriesGroup: seriesGroup,
                    isExpanded: expandedSeries.contains(seriesGroup.id),
                    expandedSeasons: $expandedSeasons,
                    onToggleExpansion: { toggleSeriesExpansion(seriesGroup.id) },
                    onPlayItem: onPlayItem,
                    onDeleteItem: onDeleteItem
                )

            case let .standalone(task):
                DownloadItemRow(
                    downloadTask: task,
                    folderSize: group.totalStorageSize,
                    onTap: { onPlayItem(task) },
                    onDelete: { onDeleteItem(task) }
                )
            }
        }
    }

    private func toggleSeriesExpansion(_ seriesId: String) {
        if expandedSeries.contains(seriesId) {
            expandedSeries.remove(seriesId)
            // Also collapse all seasons in this series
            expandedSeasons = expandedSeasons.filter { !$0.hasPrefix(seriesId) }
        } else {
            expandedSeries.insert(seriesId)
        }
    }
}

// MARK: - Series Group Row

struct SeriesGroupRow: View {
    let seriesGroup: SeriesGroup
    let isExpanded: Bool
    @Binding
    var expandedSeasons: Set<String>
    let onToggleExpansion: () -> Void
    let onPlayItem: (DownloadTask) -> Void
    let onDeleteItem: (DownloadTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Series Header
            HStack(spacing: 12) {
                // Series Thumbnail
                ImageView(seriesGroup.imageURL)
                    .failure {
                        Rectangle()
                            .foregroundColor(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "tv")
                                    .foregroundColor(.secondary)
                            }
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 60)
                    .cornerRadius(8)
                    .clipped()

                // Series Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(seriesGroup.displayTitle)
                        .font(.headline)
                        .lineLimit(1)

                    if let overview = seriesGroup.overview {
                        Text(overview)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    HStack {
                        Text("\(seriesGroup.itemCount) items")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(ByteCountFormatter.string(fromByteCount: seriesGroup.totalStorageSize, countStyle: .file))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            .contentShape(Rectangle())
            .onTapGesture {
                onToggleExpansion()
            }

            // Expanded Series Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(seriesGroup.seasons) { season in
                        SeasonGroupRow(
                            seasonGroup: season,
                            isExpanded: expandedSeasons.contains(season.id),
                            onToggleExpansion: { toggleSeasonExpansion(season.id) },
                            onPlayItem: onPlayItem,
                            onDeleteItem: onDeleteItem
                        )
                    }
                }
                .padding(.leading, 16)
            }
        }
    }

    private func toggleSeasonExpansion(_ seasonId: String) {
        if expandedSeasons.contains(seasonId) {
            expandedSeasons.remove(seasonId)
        } else {
            expandedSeasons.insert(seasonId)
        }
    }
}

// MARK: - Season Group Row

struct SeasonGroupRow: View {
    let seasonGroup: SeasonGroup
    let isExpanded: Bool
    let onToggleExpansion: () -> Void
    let onPlayItem: (DownloadTask) -> Void
    let onDeleteItem: (DownloadTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Season Header
            HStack(spacing: 12) {
                // Season Thumbnail
                ImageView(seasonGroup.imageURL)
                    .failure {
                        Rectangle()
                            .foregroundColor(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "tv")
                                    .foregroundColor(.secondary)
                            }
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 48)
                    .cornerRadius(6)
                    .clipped()

                // Season Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(seasonGroup.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    HStack {
                        Text("\(seasonGroup.itemCount) episodes")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(ByteCountFormatter.string(fromByteCount: seasonGroup.totalStorageSize, countStyle: .file))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
            .contentShape(Rectangle())
            .onTapGesture {
                onToggleExpansion()
            }

            // Expanded Season Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(seasonGroup.episodes) { episode in
                        EpisodeRow(
                            episode: episode,
                            onPlayItem: onPlayItem,
                            onDeleteItem: onDeleteItem
                        )
                    }
                }
                .padding(.leading, 12)
            }
        }
    }
}

// MARK: - Episode Row

struct EpisodeRow: View {
    let episode: EpisodeGroup
    let onPlayItem: (DownloadTask) -> Void
    let onDeleteItem: (DownloadTask) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Episode Thumbnail
            ImageView(episode.downloadTask.getImageURL(name: "Primary") ?? episode.downloadTask.getImageURL(name: "Backdrop"))
                .failure {
                    Rectangle()
                        .foregroundColor(.secondary.opacity(0.3))
                        .overlay {
                            Image(systemName: "tv")
                                .foregroundColor(.secondary)
                        }
                }
                .aspectRatio(contentMode: .fill)
                .frame(width: 70, height: 42)
                .cornerRadius(6)
                .clipped()

            // Episode Info
            VStack(alignment: .leading, spacing: 2) {
                Text(episode.displayTitle)
                    .font(.subheadline)
                    .lineLimit(1)

                if let overview = episode.downloadTask.item.overview {
                    Text(overview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    if let runtime = episode.downloadTask.item.runTimeLabel {
                        Label(runtime, systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text(ByteCountFormatter.string(fromByteCount: episode.storageSize, countStyle: .file))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)

                    Spacer()

                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            onPlayItem(episode.downloadTask)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDeleteItem(episode.downloadTask)
            } label: {
                Label(L10n.delete, systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDeleteItem(episode.downloadTask)
            } label: {
                Label("Delete Download", systemImage: "trash")
            }
        }
    }
}

// MARK: - Reusable Download Item Row (for Movies and Standalone Items)

struct DownloadItemRow: View {
    let downloadTask: DownloadTask
    let folderSize: Int64
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
                    if folderSize > 0 {
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
