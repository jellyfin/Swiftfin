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

// MARK: - Presentation Models moved from View

struct DownloadedShow: Identifiable {
    let id: String
    let seriesItem: BaseItemDto
    let episodes: [DownloadedEpisode]
    let primaryImageURL: URL?
    let backdropImageURL: URL?

    var displayTitle: String { seriesItem.displayTitle }
    var episodeCount: Int { episodes.count }
    var seasons: Set<Int> { Set(episodes.compactMap(\.seasonNumber)) }
}

struct DownloadedEpisode: Identifiable {
    let id: String
    let episodeItem: BaseItemDto
    let versionInfo: VersionInfo
    let mediaURL: URL?
    let primaryImageURL: URL?
    let backdropImageURL: URL?

    var seasonNumber: Int? { episodeItem.parentIndexNumber }
    var episodeNumber: Int? { episodeItem.indexNumber }
    var displayTitle: String { episodeItem.displayTitle }
}

struct DownloadedMovie: Identifiable {
    let id: String
    let movieItem: BaseItemDto
    let versions: [DownloadedVersion]
    let primaryImageURL: URL?
    let backdropImageURL: URL?

    var displayTitle: String { movieItem.displayTitle }
    var hasMultipleVersions: Bool { versions.count > 1 }
}

struct DownloadedVersion: Identifiable {
    let id: String
    let item: BaseItemDto
    let versionInfo: VersionInfo
    let mediaURL: URL?
    let primaryImageURL: URL?
    let backdropImageURL: URL?

    var displayName: String {
        if let mediaSourceId = versionInfo.mediaSourceId,
           let mediaSource = item.mediaSources?.first(where: { $0.id == mediaSourceId })
        {
            return mediaSource.displayTitle
        }
        if let mediaSourceId = versionInfo.mediaSourceId {
            return "Version \(mediaSourceId.prefix(8))"
        }
        return "Original Version"
    }
}

class DownloadListViewModel: ViewModel {

    @Injected(\.downloadManager)
    private var downloadManager

    // Kept for backward compatibility if referenced elsewhere
    @Published
    var items: [DownloadTask] = []

    // Published state for the view
    @Published
    private(set) var downloadedShows: [DownloadedShow] = []
    @Published
    private(set) var downloadedMovies: [DownloadedMovie] = []
    @Published
    private(set) var isLoading: Bool = false

    // MARK: - Computed presentation

    var totalStorageUsedText: String {
        guard let totalBytes = downloadManager.getTotalDownloadSize() else { return L10n.unknown }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    var totalItemCount: Int {
        let episodeCount = downloadedShows.reduce(0) { $0 + $1.episodeCount }
        let movieVersionCount = downloadedMovies.reduce(0) { $0 + $1.versions.count }
        return episodeCount + movieVersionCount
    }

    override init() {
        super.init()
        items = downloadManager.downloadedItems()
    }

    // MARK: - Intents

    @MainActor
    func load() {
        guard !isLoading else { return }
        isLoading = true
        Task { await loadDownloadedItems() }
    }

    @MainActor
    func refresh() async { await loadDownloadedItems() }

    func deleteShow(id: String) {
        logger.info("Deleting downloaded show: \(id)")
        if downloadManager.deleteDownloadedMedia(itemId: id) {
            DispatchQueue.main.async { self.downloadedShows.removeAll { $0.id == id } }
        } else {
            logger.error("Failed to delete show: \(id)")
        }
    }

    func deleteMovie(id: String) {
        logger.info("Deleting downloaded movie: \(id)")
        if downloadManager.deleteDownloadedMedia(itemId: id) {
            DispatchQueue.main.async { self.downloadedMovies.removeAll { $0.id == id } }
        } else {
            logger.error("Failed to delete movie: \(id)")
        }
    }

    func deleteAll() {
        logger.info("Deleting all downloads")
        downloadManager.deleteAllDownloadedMedia()
        DispatchQueue.main.async {
            self.downloadedShows.removeAll()
            self.downloadedMovies.removeAll()
        }
    }

    // MARK: - Loading & mapping logic moved from View

    private func createSeriesItemFromEpisode(_ episode: BaseItemDto) -> BaseItemDto {
        var seriesItem = BaseItemDto()
        seriesItem.id = episode.seriesID
        seriesItem.name = episode.seriesName
        seriesItem.type = .series
        seriesItem.overview = episode.overview
        seriesItem.productionYear = episode.productionYear
        return seriesItem
    }

    private func getSeriesPrimaryImageURL(for seriesId: String) -> URL? {
        let imagesFolder = URL.downloads.appendingPathComponent(seriesId).appendingPathComponent("Images")
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: imagesFolder.path),
           let imageFile = contents.first(where: { $0.hasPrefix("Series-\(seriesId)-Primary") })
        {
            return imagesFolder.appendingPathComponent(imageFile)
        }
        return nil
    }

    private func getSeriesBackdropImageURL(for seriesId: String) -> URL? {
        let imagesFolder = URL.downloads.appendingPathComponent(seriesId).appendingPathComponent("Images")
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: imagesFolder.path),
           let imageFile = contents.first(where: { $0.hasPrefix("Series-\(seriesId)-Backdrop") })
        {
            return imagesFolder.appendingPathComponent(imageFile)
        }
        return nil
    }

    private func getPrimaryImageURL(for itemId: String, item: BaseItemDto) -> URL? {
        getImageURL(for: itemId, item: item, imageName: "Primary")
    }

    private func getBackdropImageURL(for itemId: String, item: BaseItemDto) -> URL? {
        getImageURL(for: itemId, item: item, imageName: "Backdrop")
    }

    private func getImageURL(for itemId: String, item: BaseItemDto, imageName: String) -> URL? {
        if item.type == .episode, let seriesId = item.seriesID {
            let seriesPath = URL.downloads.appendingPathComponent(seriesId)

            if let seasonNumber = item.parentIndexNumber, let episodeId = item.id {
                let seasonFolder = seriesPath.appendingPathComponent("Season-\(String(format: "%02d", seasonNumber))")
                let seasonImagesFolder = seasonFolder.appendingPathComponent("Images")
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: seasonImagesFolder.path) {
                    if let imageFile = contents.first(where: { $0.hasPrefix("Episode-\(episodeId)-\(imageName)") }) {
                        return seasonImagesFolder.appendingPathComponent(imageFile)
                    }
                    if let seasonId = item.seasonID,
                       let imageFile = contents.first(where: { $0.hasPrefix("Season-\(seasonId)-\(imageName)") })
                    {
                        return seasonImagesFolder.appendingPathComponent(imageFile)
                    }
                }
            }

            let seriesImagesFolder = seriesPath.appendingPathComponent("Images")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: seriesImagesFolder.path),
               let imageFile = contents.first(where: { $0.hasPrefix("Series-\(seriesId)-\(imageName)") })
            {
                return seriesImagesFolder.appendingPathComponent(imageFile)
            }
            return nil
        } else {
            let imagesFolder = URL.downloads.appendingPathComponent(itemId).appendingPathComponent("Images")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: imagesFolder.path),
               let imageFile = contents.first(where: { $0.hasPrefix(imageName) })
            {
                return imagesFolder.appendingPathComponent(imageFile)
            }
            return nil
        }
    }

    private func getMediaURL(for itemId: String, versionInfo: VersionInfo) -> URL? {
        let downloadPath = URL.downloads.appendingPathComponent(itemId)
        if let enumerator = FileManager.default.enumerator(
            at: downloadPath,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let url as URL in enumerator {
                let filename = url.lastPathComponent
                guard !filename.contains("metadata") else { continue }
                if let msid = versionInfo.mediaSourceId, filename.contains(msid) { return url }
                if filename.hasPrefix("Media.") || filename.contains(itemId) { return url }
            }
        }
        return nil
    }

    private func inferEpisodeId(in seasonFolder: URL, versionInfo: VersionInfo) -> String? {
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: seasonFolder.path) {
            let candidates = contents.filter { filename in
                guard !filename.contains("metadata") else { return false }
                if let msid = versionInfo.mediaSourceId, filename.contains(msid) { return true }
                return filename.contains("-")
            }
            if let match = candidates.first, let dash = match.firstIndex(of: "-") {
                return String(match[..<dash])
            }
        }
        return nil
    }

    @MainActor
    private func loadDownloadedItems() async {
        logger.info("Loading downloaded items from filesystem")
        defer { isLoading = false }

        let downloadedItemIds = downloadManager.getDownloadedItemIds()
        logger.info("Found \(downloadedItemIds.count) downloaded item folders")

        var showsDict: [String: (seriesItem: BaseItemDto, episodes: [DownloadedEpisode])] = [:]
        var moviesArray: [DownloadedMovie] = []

        for itemId in downloadedItemIds {
            let itemPath = URL.downloads.appendingPathComponent(itemId)
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: itemPath.path) else { continue }
            let seasonFolders = contents.filter { $0.hasPrefix("Season-") }

            if !seasonFolders.isEmpty {
                var allEpisodes: [DownloadedEpisode] = []
                var seriesItem: BaseItemDto?

                for seasonFolder in seasonFolders.sorted() {
                    let seasonPath = itemPath.appendingPathComponent(seasonFolder)
                    let seasonMetadataFile = seasonPath.appendingPathComponent("metadata.json")

                    guard let seasonData = FileManager.default.contents(atPath: seasonMetadataFile.path),
                          let seasonMetadata = try? JSONDecoder().decode(DownloadMetadata.self, from: seasonData)
                    else { continue }

                    for versionInfo in seasonMetadata.versions {
                        var episodeItem: BaseItemDto?

                        if let epId = versionInfo.episodeId, let epItem = seasonMetadata.episodes?[epId] {
                            episodeItem = epItem
                        } else if let inferredId = inferEpisodeId(in: seasonPath, versionInfo: versionInfo),
                                  let epItem = seasonMetadata.episodes?[inferredId]
                        {
                            episodeItem = epItem
                        } else if let templateItem = seasonMetadata.item, templateItem.type == .episode {
                            episodeItem = templateItem
                        }

                        if let episodeItem {
                            if seriesItem == nil { seriesItem = createSeriesItemFromEpisode(episodeItem) }

                            let mediaURL = getMediaURL(for: itemId, versionInfo: versionInfo)
                            let primaryImageURL = getPrimaryImageURL(for: itemId, item: episodeItem)
                            let backdropImageURL = getBackdropImageURL(for: itemId, item: episodeItem)

                            let downloadedEpisode = DownloadedEpisode(
                                id: (episodeItem.id ?? UUID().uuidString) + ":" + versionInfo.versionId,
                                episodeItem: episodeItem,
                                versionInfo: versionInfo,
                                mediaURL: mediaURL,
                                primaryImageURL: primaryImageURL,
                                backdropImageURL: backdropImageURL
                            )
                            allEpisodes.append(downloadedEpisode)
                        }
                    }
                }

                if let seriesItem, !allEpisodes.isEmpty {
                    showsDict[itemId] = (seriesItem: seriesItem, episodes: allEpisodes)
                }
            } else {
                guard let metadata = downloadManager.getDownloadMetadata(for: itemId), let item = metadata.item else { continue }

                switch item.type {
                case .episode:
                    if let seriesId = item.seriesID {
                        if showsDict[seriesId] ==
                            nil { showsDict[seriesId] = (seriesItem: createSeriesItemFromEpisode(item), episodes: []) }
                        for versionInfo in metadata.versions {
                            let mediaURL = getMediaURL(for: itemId, versionInfo: versionInfo)
                            let primaryImageURL = getPrimaryImageURL(for: itemId, item: item)
                            let backdropImageURL = getBackdropImageURL(for: itemId, item: item)

                            showsDict[seriesId]?.episodes.append(
                                DownloadedEpisode(
                                    id: (item.id ?? UUID().uuidString) + ":" + versionInfo.versionId,
                                    episodeItem: item,
                                    versionInfo: versionInfo,
                                    mediaURL: mediaURL,
                                    primaryImageURL: primaryImageURL,
                                    backdropImageURL: backdropImageURL
                                )
                            )
                        }
                    }
                case .movie:
                    var downloadedVersions: [DownloadedVersion] = []
                    for versionInfo in metadata.versions {
                        let mediaURL = getMediaURL(for: itemId, versionInfo: versionInfo)
                        let primaryImageURL = getPrimaryImageURL(for: itemId, item: item)
                        let backdropImageURL = getBackdropImageURL(for: itemId, item: item)

                        downloadedVersions.append(
                            DownloadedVersion(
                                id: versionInfo.versionId,
                                item: item,
                                versionInfo: versionInfo,
                                mediaURL: mediaURL,
                                primaryImageURL: primaryImageURL,
                                backdropImageURL: backdropImageURL
                            )
                        )
                    }
                    if !downloadedVersions.isEmpty {
                        let primaryImageURL = getPrimaryImageURL(for: itemId, item: item)
                        let backdropImageURL = getBackdropImageURL(for: itemId, item: item)
                        let downloadedMovie = DownloadedMovie(
                            id: item.id ?? UUID().uuidString,
                            movieItem: item,
                            versions: downloadedVersions,
                            primaryImageURL: primaryImageURL,
                            backdropImageURL: backdropImageURL
                        )
                        moviesArray.append(downloadedMovie)
                    }
                default:
                    continue
                }
            }
        }

        var showsArray: [DownloadedShow] = []
        for (seriesId, seriesData) in showsDict {
            let primaryImageURL = getSeriesPrimaryImageURL(for: seriesId)
            let backdropImageURL = getSeriesBackdropImageURL(for: seriesId)

            let sortedEpisodes = seriesData.episodes.sorted {
                if let s1 = $0.seasonNumber, let s2 = $1.seasonNumber, s1 != s2 { return s1 < s2 }
                if let e1 = $0.episodeNumber, let e2 = $1.episodeNumber, e1 != e2 { return e1 < e2 }
                return $0.displayTitle < $1.displayTitle
            }

            showsArray.append(
                DownloadedShow(
                    id: seriesData.seriesItem.id ?? UUID().uuidString,
                    seriesItem: seriesData.seriesItem,
                    episodes: sortedEpisodes,
                    primaryImageURL: primaryImageURL,
                    backdropImageURL: backdropImageURL
                )
            )
        }

        downloadedShows = showsArray.sorted { $0.displayTitle < $1.displayTitle }
        downloadedMovies = moviesArray.sorted { $0.displayTitle < $1.displayTitle }
    }
}
