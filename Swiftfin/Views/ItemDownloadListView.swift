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

struct ItemDownloadListView: View {

    // MARK: - Properties

    @Router
    private var router

    let item: BaseItemDto

    // MARK: - State

    @StateObject
    private var downloadManager = Container.shared.downloadManager()

    @State
    private var downloadedEpisodes: [DownloadedEpisode] = []

    @State
    private var episodesBySeason: [Int: [DownloadedEpisode]] = [:]

    @State
    private var isLoading = true

    @State
    private var showingDeleteAlert = false

    @State
    private var episodeToDelete: DownloadedEpisode?

    // MARK: - Dependencies

    private let logger = Logger.swiftfin()

    // MARK: - Computed Properties

    private var sortedSeasons: [Int] {
        Array(episodesBySeason.keys).sorted()
    }

    private var totalEpisodeCount: Int {
        downloadedEpisodes.count
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading episodes...")
                        .foregroundStyle(.secondary)
                }
            } else if downloadedEpisodes.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .navigationTitle(item.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Episode", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                episodeToDelete = nil
            }
            Button("Delete", role: .destructive) {
                confirmDeleteEpisode()
            }
        } message: {
            if let episodeToDelete = episodeToDelete {
                Text("Are you sure you want to delete '\(episodeToDelete.displayTitle)'?")
            }
        }
        .onAppear {
            loadDownloadedEpisodes()
        }
    }

    // MARK: - Empty State View

    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)

            Text("No Downloaded Episodes")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Episodes for this series haven't been downloaded yet")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {

        List {

            // Episodes grouped by season
            ForEach(sortedSeasons, id: \.self) { seasonNumber in
                Section(header: seasonHeader(for: seasonNumber)) {
                    if let episodes = episodesBySeason[seasonNumber] {
                        ForEach(episodes) { episode in
                            DownloadedEpisodeRow(
                                episode: episode,
                                onTap: { handleEpisodeTap(episode) },
                                onDelete: { deleteEpisode(episode) }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Season Header

    @ViewBuilder
    private func seasonHeader(for seasonNumber: Int) -> some View {
        HStack {
            Text("Season \(seasonNumber)")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            if let episodes = episodesBySeason[seasonNumber] {
                Text("\(episodes.count) episodes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Private Methods

    private func loadDownloadedEpisodes() {
        guard let seriesId = item.id else {
            logger.error("No series ID provided")
            isLoading = false
            return
        }

        logger.info("Loading downloaded episodes for series: \(item.displayTitle)")

        // Look for episodes in season folders within the series directory
        let seriesPath = URL.downloads.appendingPathComponent(seriesId)

        var episodes: [DownloadedEpisode] = []

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: seriesPath.path)
            let seasonFolders = contents.filter { $0.hasPrefix("Season-") }

            logger.info("Found \(seasonFolders.count) season folders for series: \(item.displayTitle)")

            for seasonFolder in seasonFolders.sorted() {
                let seasonPath = seriesPath.appendingPathComponent(seasonFolder)
                let seasonMetadataFile = seasonPath.appendingPathComponent("metadata.json")

                // Read season metadata which contains episode information
                if let seasonData = FileManager.default.contents(atPath: seasonMetadataFile.path),
                   let seasonMetadata = try? JSONDecoder().decode(DownloadMetadata.self, from: seasonData)
                {

                    logger.debug("Processing season folder: \(seasonFolder) with \(seasonMetadata.versions.count) versions")

                    // For series structured folders, each version represents an episode.
                    // Prefer per-episode metadata when available; otherwise fall back to template.
                    for versionInfo in seasonMetadata.versions {
                        var episodeItem: BaseItemDto?

                        // 1) Use explicit per-episode metadata if present
                        if let epId = versionInfo.episodeId, let epItem = seasonMetadata.episodes?[epId] {
                            episodeItem = epItem
                        }

                        // 2) Fallback: try to infer episodeId from media file name in season folder
                        if episodeItem == nil {
                            if let inferredId = inferEpisodeId(in: seasonPath, versionInfo: versionInfo) {
                                episodeItem = seasonMetadata.episodes?[inferredId]
                            }
                        }

                        // 3) Last resort: use season-level template
                        if episodeItem == nil, let templateItem = seasonMetadata.item, templateItem.type == .episode {
                            episodeItem = templateItem
                        }

                        if let episodeItem = episodeItem {
                            let mediaURL = getMediaURL(for: seriesId, episodeItem: episodeItem, versionInfo: versionInfo)
                            let primaryImageURL = getPrimaryImageURL(for: seriesId, episodeItem: episodeItem)
                            let backdropImageURL = getBackdropImageURL(for: seriesId, episodeItem: episodeItem)

                            let downloadedEpisode = DownloadedEpisode(
                                episodeItem: episodeItem,
                                versionInfo: versionInfo,
                                mediaURL: mediaURL,
                                primaryImageURL: primaryImageURL,
                                backdropImageURL: backdropImageURL
                            )

                            episodes.append(downloadedEpisode)
                        }
                    }
                }
            }
        } catch {
            logger.error("Failed to read series directory contents: \(error)")
            isLoading = false
            return
        }

        // Group episodes by season
        var grouped: [Int: [DownloadedEpisode]] = [:]

        for episode in episodes {
            let seasonNumber = episode.seasonNumber ?? 1 // Default to season 1 if not specified
            if grouped[seasonNumber] == nil {
                grouped[seasonNumber] = []
            }
            grouped[seasonNumber]?.append(episode)
        }

        // Sort episodes within each season
        for seasonNumber in grouped.keys {
            grouped[seasonNumber]?.sort { episode1, episode2 in
                if let ep1 = episode1.episodeNumber, let ep2 = episode2.episodeNumber {
                    return ep1 < ep2
                }
                return episode1.displayTitle < episode2.displayTitle
            }
        }

        downloadedEpisodes = episodes.sorted { episode1, episode2 in
            if let season1 = episode1.seasonNumber, let season2 = episode2.seasonNumber {
                if season1 != season2 {
                    return season1 < season2
                }
            }
            if let ep1 = episode1.episodeNumber, let ep2 = episode2.episodeNumber {
                return ep1 < ep2
            }
            return episode1.displayTitle < episode2.displayTitle
        }

        episodesBySeason = grouped
        isLoading = false

        logger.info("Loaded \(episodes.count) episodes across \(grouped.keys.count) seasons")
    }

    // Try to infer the episodeId from filenames like "[episodeId]-[versionId].ext"
    private func inferEpisodeId(in seasonFolder: URL, versionInfo: VersionInfo) -> String? {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: seasonFolder.path)
            // Prefer matching by version mediaSourceId when present
            let candidates = contents.filter { filename in
                guard !filename.contains("metadata") else { return false }
                if let msid = versionInfo.mediaSourceId, filename.contains(msid) { return true }
                // Otherwise, match pattern like "<episodeId>-<versionId>"
                return filename.contains("-")
            }
            // Parse episodeId as prefix up to first '-'
            if let match = candidates.first {
                if let dash = match.firstIndex(of: "-") {
                    let prefix = String(match[..<dash])
                    return prefix
                }
            }
        } catch {
            logger.debug("Failed to infer episode id from season folder: \(error)")
        }
        return nil
    }

    private func getMediaURL(for seriesId: String, episodeItem: BaseItemDto, versionInfo: VersionInfo) -> URL? {
        let seriesPath = URL.downloads.appendingPathComponent(seriesId)

        // Check season folders
        if let seasonNumber = episodeItem.parentIndexNumber {
            let seasonFolder = seriesPath.appendingPathComponent("Season-\(String(format: "%02d", seasonNumber))")

            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: seasonFolder.path)

                // Look for media file for this episode/version
                if let mediaSourceId = versionInfo.mediaSourceId {
                    if let mediaFile = contents.first(where: { $0.contains(mediaSourceId) && !$0.contains("metadata") }) {
                        return seasonFolder.appendingPathComponent(mediaFile)
                    }
                }

                // Fallback to episode ID
                if let episodeId = episodeItem.id {
                    if let mediaFile = contents.first(where: { $0.contains(episodeId) && !$0.contains("metadata") }) {
                        return seasonFolder.appendingPathComponent(mediaFile)
                    }
                }

                // Fallback to generic media file
                if let mediaFile = contents.first(where: { $0.hasPrefix("Media.") }) {
                    return seasonFolder.appendingPathComponent(mediaFile)
                }
            } catch {
                logger.warning("Error reading season folder: \(error)")
            }
        }

        return nil
    }

    private func getPrimaryImageURL(for seriesId: String, episodeItem: BaseItemDto) -> URL? {
        getImageURL(for: seriesId, episodeItem: episodeItem, imageName: "Primary")
    }

    private func getBackdropImageURL(for seriesId: String, episodeItem: BaseItemDto) -> URL? {
        getImageURL(for: seriesId, episodeItem: episodeItem, imageName: "Backdrop")
    }

    private func getImageURL(for seriesId: String, episodeItem: BaseItemDto, imageName: String) -> URL? {
        let seriesPath = URL.downloads.appendingPathComponent(seriesId)

        // 1. First try episode-specific images in season folder
        if let seasonNumber = episodeItem.parentIndexNumber, let episodeId = episodeItem.id {
            let seasonFolder = seriesPath.appendingPathComponent("Season-\(String(format: "%02d", seasonNumber))")
            let seasonImagesFolder = seasonFolder.appendingPathComponent("Images")

            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: seasonImagesFolder.path)
                // Look for episode-specific image: Episode-[episodeId]-{Primary|Backdrop}.*
                if let imageFile = contents.first(where: { $0.hasPrefix("Episode-\(episodeId)-\(imageName)") }) {
                    logger.debug("Found episode-specific \(imageName) image: \(imageFile)")
                    return seasonImagesFolder.appendingPathComponent(imageFile)
                }

                // 2. Fallback to season-specific images in same folder
                if let seasonId = episodeItem.seasonID {
                    if let imageFile = contents.first(where: { $0.hasPrefix("Season-\(seasonId)-\(imageName)") }) {
                        logger.debug("Found season-specific \(imageName) image: \(imageFile)")
                        return seasonImagesFolder.appendingPathComponent(imageFile)
                    }
                }
            } catch {
                // Season images folder doesn't exist, continue to series level
                logger.debug("No season Images folder found for episode: \(episodeItem.displayTitle)")
            }
        }

        // 3. Fallback to series-level images
        let seriesImagesFolder = seriesPath.appendingPathComponent("Images")
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: seriesImagesFolder.path)
            // Look for series-specific image: Series-[seriesId]-{Primary|Backdrop}.*
            if let imageFile = contents.first(where: { $0.hasPrefix("Series-\(seriesId)-\(imageName)") }) {
                logger.debug("Found series-specific \(imageName) image: \(imageFile)")
                return seriesImagesFolder.appendingPathComponent(imageFile)
            }
        } catch {
            // Series images folder doesn't exist
            logger.debug("No series Images folder found for series: \(seriesId)")
        }

        logger.debug("No \(imageName) image found for episode: \(episodeItem.displayTitle)")
        return nil
    }

    private func handleEpisodeTap(_ episode: DownloadedEpisode) {
        logger.info("User tapped on episode: \(episode.displayTitle)")
        // Navigate to episode player
        router.route(to: .item(item: episode.episodeItem))
    }

    private func deleteEpisode(_ episode: DownloadedEpisode) {
        logger.info("User requested to delete episode: \(episode.displayTitle)")
        episodeToDelete = episode
        showingDeleteAlert = true
    }

    private func confirmDeleteEpisode() {
        guard let episodeToDelete = episodeToDelete,
              let episodeId = episodeToDelete.episodeItem.id else { return }

        logger.info("Confirming deletion of episode: \(episodeToDelete.displayTitle)")

        // For episodes, we need to delete from the series folder
        let success = downloadManager.deleteDownloadedMedia(itemId: episodeId)

        if success {
            // Remove from UI
            downloadedEpisodes.removeAll { $0.id == episodeToDelete.id }

            // Update grouped episodes
            loadDownloadedEpisodes()

            logger.info("Successfully deleted episode from UI")
        } else {
            logger.error("Failed to delete episode for item: \(episodeId)")
        }

        self.episodeToDelete = nil
    }
}

// MARK: - Downloaded Episode Row

struct DownloadedEpisodeRow: View {

    // MARK: - Properties

    let episode: DownloadedEpisode
    let onTap: () -> Void
    let onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 6) {
            // Thumbnail
            ImageView(episode.backdropImageURL)
                .failure {
                    Rectangle()
                        .foregroundStyle(.secondary.opacity(0.3))
                        .overlay {
                            Image(systemName: "tv")
                        }
                }
                .aspectRatio(16 / 9, contentMode: .fill)
                .frame(width: 120, height: 67.5)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Episode info
            VStack(alignment: .leading, spacing: 4) {
                // Episode number and title
                HStack {
                    if let episodeNumber = episode.episodeNumber {
                        Text("Episode \(episodeNumber)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }

                    if let runtime = episode.episodeItem.runTimeTicks {
                        let minutes = runtime / 600_000_000
                        Text("\(minutes)m")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Spacer()

                    // Delete button
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }

                Text(episode.displayTitle)
                    .font(.system(size: 13, weight: .semibold)) // Between subheadline (~15) and caption (~12)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let overview = episode.episodeItem.overview {
                    Text(overview)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
