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

                    for versionInfo in seasonMetadata.versions {
                        var episodeItem: BaseItemDto?

                        if let epId = versionInfo.episodeId, let epItem = seasonMetadata.episodes?[epId] {
                            episodeItem = epItem
                        }

                        if episodeItem == nil {
                            if let inferredId = inferEpisodeId(in: seasonPath, versionInfo: versionInfo) {
                                episodeItem = seasonMetadata.episodes?[inferredId]
                            }
                        }

                        if episodeItem == nil, let templateItem = seasonMetadata.item, templateItem.type == .episode {
                            episodeItem = templateItem
                        }

                        if let episodeItem {
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
                        }
                    }
                }
            }
        } catch {
            logger.error("Failed to read series directory contents: \(error)")
            return
        }

        // Sort & assign
        downloadedEpisodes = sortEpisodes(episodes)
        regroupEpisodes()
        logger.info("Loaded \(episodes.count) episodes across \(episodesBySeason.keys.count) seasons")
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
                guard !filename.contains("metadata") else { return false }
                if let msid = versionInfo.mediaSourceId, filename.contains(msid) { return true }
                return filename.contains("-")
            }
            if let match = candidates.first, let dash = match.firstIndex(of: "-") {
                let prefix = String(match[..<dash])
                return prefix
            }
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
