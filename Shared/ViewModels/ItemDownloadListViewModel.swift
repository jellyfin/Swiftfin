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

final class ItemDownloadListViewModel: ViewModel {

    // MARK: - Input

    let seriesItem: BaseItemDto

    // MARK: - Dependencies

    @Injected(\.downloadManager)
    private var downloadManager

    // MARK: - Published State

    @Published
    private(set) var downloadedEpisodes: [DownloadedEpisode] = []
    @Published
    private(set) var episodesBySeason: [Int: [DownloadedEpisode]] = [:]
    @Published
    private(set) var isLoading: Bool = false

    // MARK: - Computed Presentation

    var sortedSeasons: [Int] { Array(episodesBySeason.keys).sorted() }
    var totalEpisodeCount: Int { downloadedEpisodes.count }

    // MARK: - Init

    init(item: BaseItemDto) {
        self.seriesItem = item
    }

    // MARK: - Intents

    @MainActor
    func load() {
        guard !isLoading else { return }
        isLoading = true
        Task { await loadDownloadedEpisodes() }
    }

    @MainActor
    func refresh() async { await loadDownloadedEpisodes() }

    func deleteEpisode(_ episode: DownloadedEpisode) {
        guard let episodeId = episode.episodeItem.id else { return }
        logger.info("Confirming deletion of episode: \(episode.displayTitle)")

        let success = downloadManager.deleteDownloadedMedia(itemId: episodeId)
        if success {
            DispatchQueue.main.async {
                self.downloadedEpisodes.removeAll { $0.id == episode.id }
                self.regroupEpisodes()
            }
            logger.info("Successfully deleted episode from UI")
        } else {
            logger.error("Failed to delete episode for item: \(episodeId)")
        }
    }

    // MARK: - Loading & Mapping Logic

    @MainActor
    private func loadDownloadedEpisodes() async {
        defer { isLoading = false }
        guard let seriesId = seriesItem.id else {
            logger.error("No series ID provided")
            return
        }

        logger.info("Loading downloaded episodes for series: \(seriesItem.displayTitle)")
        let seriesPath = URL.downloads.appendingPathComponent(seriesId)

        var episodes: [DownloadedEpisode] = []
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: seriesPath.path)
            let seasonFolders = contents.filter { $0.hasPrefix("Season-") }
            logger.info("Found \(seasonFolders.count) season folders for series: \(seriesItem.displayTitle)")

            for seasonFolder in seasonFolders.sorted() {
                let seasonPath = seriesPath.appendingPathComponent(seasonFolder)
                let seasonMetadataFile = seasonPath.appendingPathComponent("metadata.json")

                if let seasonData = FileManager.default.contents(atPath: seasonMetadataFile.path),
                   let seasonMetadata = try? JSONDecoder().decode(DownloadMetadata.self, from: seasonData)
                {
                    logger.debug("Processing season folder: \(seasonFolder) with \(seasonMetadata.versions.count) versions")
                    logger.debug("Season episodes dictionary has \(seasonMetadata.episodes?.count ?? 0) entries")

                    // Log the episode IDs in the episodes dictionary for debugging
                    if let episodesDict = seasonMetadata.episodes {
                        logger.debug("Available episode IDs: \(Array(episodesDict.keys))")
                    }

                    if let episodesDict = seasonMetadata.episodes, !episodesDict.isEmpty {
                        // New strategy: Iterate over the episodes dictionary which is the source of truth for what episodes exist.
                        for (episodeId, episodeItem) in episodesDict {
                            logger.debug("Processing episode from dictionary: \(episodeItem.displayTitle) (ID: \(episodeId))")

                            // Find a matching version from the (potentially incomplete) versions array.
                            let versionInfo = seasonMetadata.versions.first {
                                $0.episodeId == episodeId || $0.versionId == episodeId || $0.mediaSourceId == episodeId
                            }

                            // If no version info is found, we can still proceed if we can find the media file.
                            // We create a "best-effort" versionInfo object.
                            let finalVersionInfo = versionInfo ?? VersionInfo(
                                versionId: episodeId,
                                container: "mp4", // Assume default, actual extension will be in URL
                                isStatic: true,
                                mediaSourceId: episodeId,
                                episodeId: episodeId,
                                downloadDate: "",
                                taskId: ""
                            )

                            let mediaURL = getMediaURL(for: seriesId, episodeItem: episodeItem, versionInfo: finalVersionInfo)

                            // We must have a media file to consider this a downloaded episode.
                            guard let finalMediaURL = mediaURL, FileManager.default.fileExists(atPath: finalMediaURL.path) else {
                                logger
                                    .warning(
                                        "Could not find media file for episode '\(episodeItem.displayTitle)'. It might have been deleted or metadata is out of sync. Skipping."
                                    )
                                continue
                            }

                            let primaryImageURL = getPrimaryImageURL(for: seriesId, episodeItem: episodeItem)
                            let backdropImageURL = getBackdropImageURL(for: seriesId, episodeItem: episodeItem)

                            let downloadedEpisode = DownloadedEpisode(
                                id: (episodeItem.id ?? UUID().uuidString) + ":" + finalVersionInfo.versionId,
                                episodeItem: episodeItem,
                                versionInfo: finalVersionInfo,
                                mediaURL: finalMediaURL,
                                primaryImageURL: primaryImageURL,
                                backdropImageURL: backdropImageURL
                            )

                            episodes.append(downloadedEpisode)
                        }
                    } else {
                        // Fallback for older metadata that might not have the 'episodes' dictionary.
                        logger.debug("Falling back to iterating over versions array.")
                        for versionInfo in seasonMetadata.versions {
                            logger
                                .debug(
                                    "Processing version: versionId=\(versionInfo.versionId), episodeId=\(versionInfo.episodeId ?? "nil"), mediaSourceId=\(versionInfo.mediaSourceId ?? "nil")"
                                )

                            var episodeItem: BaseItemDto?

                            // First try: Use explicit episodeId from versionInfo
                            if let epId = versionInfo.episodeId, let epItem = seasonMetadata.episodes?[epId] {
                                episodeItem = epItem
                                logger.debug("Found episode using explicit episodeId: \(epId)")
                            }

                            // Second try: Infer episodeId from filename and lookup in episodes dictionary
                            if episodeItem == nil {
                                if let inferredId = inferEpisodeId(in: seasonPath, versionInfo: versionInfo) {
                                    episodeItem = seasonMetadata.episodes?[inferredId]
                                    if episodeItem != nil {
                                        logger.debug("Found episode using inferred episodeId: \(inferredId)")
                                    } else {
                                        logger.debug("Inferred episodeId '\(inferredId)' not found in episodes dictionary")
                                    }
                                }
                            }

                            // Third try: Use mediaSourceId as episodeId (fallback)
                            if episodeItem == nil, let mediaSourceId = versionInfo.mediaSourceId {
                                episodeItem = seasonMetadata.episodes?[mediaSourceId]
                                if episodeItem != nil {
                                    logger.debug("Found episode using mediaSourceId as episodeId: \(mediaSourceId)")
                                }
                            }

                            // Fourth try: Use versionId as episodeId (fallback)
                            if episodeItem == nil {
                                episodeItem = seasonMetadata.episodes?[versionInfo.versionId]
                                if episodeItem != nil {
                                    logger.debug("Found episode using versionId as episodeId: \(versionInfo.versionId)")
                                }
                            }

                            // REMOVED: Don't fall back to template item as it causes all episodes to appear as the same episode
                            // This fallback was causing multiple different episodes to be treated as the same episode

                            // Only process if we successfully found a specific episode item
                            if let episodeItem {
                                logger.debug("Successfully found episode: \(episodeItem.displayTitle)")

                                let mediaURL = getMediaURL(for: seriesId, episodeItem: episodeItem, versionInfo: versionInfo)
                                let primaryImageURL = getPrimaryImageURL(for: seriesId, episodeItem: episodeItem)
                                let backdropImageURL = getBackdropImageURL(for: seriesId, episodeItem: episodeItem)

                                let downloadedEpisode = DownloadedEpisode(
                                    id: (episodeItem.id ?? UUID().uuidString) + ":" + versionInfo.versionId,
                                    episodeItem: episodeItem,
                                    versionInfo: versionInfo,
                                    mediaURL: mediaURL,
                                    primaryImageURL: primaryImageURL,
                                    backdropImageURL: backdropImageURL
                                )

                                episodes.append(downloadedEpisode)
                            } else {
                                logger.warning("Could not find episode item for version \(versionInfo.versionId) - skipping")
                            }
                        }
                    }
                }
            }
        } catch {
            logger.error("Failed to read series directory contents: \(error)")
            return
        }

        logger.debug("--------------------------------------------------------------------------------")

        logger.debug("episodes.count \(episodes.count) ")
        logger.debug("seriesId \(seriesId) ")

        logger.debug("--------------------------------------------------------------------------------")

        // Sort & assign with deduplication
        downloadedEpisodes = deduplicateEpisodes(sortEpisodes(episodes))
        regroupEpisodes()
        logger
            .info(
                "Loaded \(downloadedEpisodes.count) unique episodes across \(episodesBySeason.keys.count) seasons (from \(episodes.count) total versions)"
            )
    }

    private func deduplicateEpisodes(_ episodes: [DownloadedEpisode]) -> [DownloadedEpisode] {
        var uniqueEpisodes: [DownloadedEpisode] = []
        var seenEpisodeIds: Set<String> = []
        return episodes
        for episode in episodes {
            if let episodeId = episode.episodeItem.id, !seenEpisodeIds.contains(episodeId) {
                seenEpisodeIds.insert(episodeId)
                uniqueEpisodes.append(episode)
            } else if episode.episodeItem.id == nil {
                // If episode has no ID, use a combination of season + episode number for uniqueness
                let uniqueKey = "\(episode.seasonNumber ?? 0)_\(episode.episodeNumber ?? 0)"
                if !seenEpisodeIds.contains(uniqueKey) {
                    seenEpisodeIds.insert(uniqueKey)
                    uniqueEpisodes.append(episode)
                }
            }
        }

        logger.debug("Deduplicated from \(episodes.count) to \(uniqueEpisodes.count) episodes")
        return uniqueEpisodes
    }

    private func regroupEpisodes() {
        var grouped: [Int: [DownloadedEpisode]] = [:]
        for episode in downloadedEpisodes {
            let seasonNumber = episode.seasonNumber ?? 1
            grouped[seasonNumber, default: []].append(episode)
        }
        for key in grouped.keys {
            grouped[key]?.sort(by: episodeSortComparator)
        }
        episodesBySeason = grouped
    }

    private func sortEpisodes(_ episodes: [DownloadedEpisode]) -> [DownloadedEpisode] {
        episodes.sorted(by: { lhs, rhs in
            if let s1 = lhs.seasonNumber, let s2 = rhs.seasonNumber, s1 != s2 { return s1 < s2 }
            if let e1 = lhs.episodeNumber, let e2 = rhs.episodeNumber, e1 != e2 { return e1 < e2 }
            return lhs.displayTitle < rhs.displayTitle
        })
    }

    private func episodeSortComparator(_ e1: DownloadedEpisode, _ e2: DownloadedEpisode) -> Bool {
        if let n1 = e1.episodeNumber, let n2 = e2.episodeNumber { return n1 < n2 }
        return e1.displayTitle < e2.displayTitle
    }

    // Try to infer the episodeId from filenames like "[episodeId]-[versionId].ext"
    private func inferEpisodeId(in seasonFolder: URL, versionInfo: VersionInfo) -> String? {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: seasonFolder.path)
            let candidates = contents.filter { filename in
                guard !filename.contains("metadata") && !filename.hasPrefix(".") else { return false }
                // First try: match by mediaSourceId if available
                if let msid = versionInfo.mediaSourceId, filename.contains(msid) { return true }
                // Second try: match by versionId
                if filename.contains(versionInfo.versionId) { return true }
                // Third try: any file with dash pattern
                return filename.contains("-")
            }

            // Try to extract episode ID from filename
            for candidate in candidates {
                // Look for pattern: [episodeId]-[versionId].ext
                if let dash = candidate.firstIndex(of: "-") {
                    let prefix = String(candidate[..<dash])
                    // Validate that prefix looks like an episode ID (UUID format typically)
                    if prefix.count > 10 { // Basic validation - episode IDs are usually long UUIDs
                        logger.debug("Inferred episode ID '\(prefix)' from filename '\(candidate)'")
                        return prefix
                    }
                }
            }

            logger.debug("Failed to infer episode ID from filenames: \(candidates)")
        } catch {
            logger.debug("Failed to infer episode id from season folder: \(error)")
        }
        return nil
    }

    private func getMediaURL(for seriesId: String, episodeItem: BaseItemDto, versionInfo: VersionInfo) -> URL? {
        let seriesPath = URL.downloads.appendingPathComponent(seriesId)
        if let seasonNumber = episodeItem.parentIndexNumber {
            let seasonFolder = seriesPath.appendingPathComponent("Season-\(String(format: "%02d", seasonNumber))")
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: seasonFolder.path)
                if let mediaSourceId = versionInfo.mediaSourceId,
                   let mediaFile = contents.first(where: { $0.contains(mediaSourceId) && !$0.contains("metadata") })
                {
                    return seasonFolder.appendingPathComponent(mediaFile)
                }
                if let episodeId = episodeItem.id,
                   let mediaFile = contents.first(where: { $0.contains(episodeId) && !$0.contains("metadata") })
                {
                    return seasonFolder.appendingPathComponent(mediaFile)
                }
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
        if let seasonNumber = episodeItem.parentIndexNumber, let episodeId = episodeItem.id {
            let seasonFolder = seriesPath.appendingPathComponent("Season-\(String(format: "%02d", seasonNumber))")
            let seasonImagesFolder = seasonFolder.appendingPathComponent("Images")
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: seasonImagesFolder.path)
                if let imageFile = contents.first(where: { $0.hasPrefix("Episode-\(episodeId)-\(imageName)") }) {
                    return seasonImagesFolder.appendingPathComponent(imageFile)
                }
                if let seasonId = episodeItem.seasonID,
                   let imageFile = contents.first(where: { $0.hasPrefix("Season-\(seasonId)-\(imageName)") })
                {
                    return seasonImagesFolder.appendingPathComponent(imageFile)
                }
            } catch {
                logger.debug("No season Images folder found for episode: \(episodeItem.displayTitle)")
            }
        }
        let seriesImagesFolder = seriesPath.appendingPathComponent("Images")
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: seriesImagesFolder.path)
            if let imageFile = contents.first(where: { $0.hasPrefix("Series-\(seriesId)-\(imageName)") }) {
                return seriesImagesFolder.appendingPathComponent(imageFile)
            }
        } catch {
            logger.debug("No series Images folder found for series: \(seriesId)")
        }
        return nil
    }
}
