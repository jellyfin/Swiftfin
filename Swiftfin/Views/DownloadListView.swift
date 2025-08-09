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

// MARK: - Downloaded Show (Series with Episodes)

struct DownloadedShow: Identifiable {
    let id: String
    let seriesItem: BaseItemDto
    let episodes: [DownloadedEpisode]
    let primaryImageURL: URL?
    let backdropImageURL: URL?

    var displayTitle: String { seriesItem.displayTitle }
    var episodeCount: Int { episodes.count }
    var seasons: Set<Int> {
        Set(episodes.compactMap(\.seasonNumber))
    }

    init(seriesItem: BaseItemDto, episodes: [DownloadedEpisode], primaryImageURL: URL? = nil, backdropImageURL: URL? = nil) {
        self.id = seriesItem.id ?? UUID().uuidString
        self.seriesItem = seriesItem
        self.episodes = episodes
        self.primaryImageURL = primaryImageURL
        self.backdropImageURL = backdropImageURL
    }
}

// MARK: - Downloaded Episode

struct DownloadedEpisode: Identifiable {
    let id: String
    let episodeItem: BaseItemDto
    let versionInfo: VersionInfo
    let mediaURL: URL?
    let primaryImageURL: URL?
    let backdropImageURL: URL?
    let episodeImageURL: URL?

    var seasonNumber: Int? { episodeItem.parentIndexNumber }
    var episodeNumber: Int? { episodeItem.indexNumber }
    var displayTitle: String { episodeItem.displayTitle }

    init(
        episodeItem: BaseItemDto,
        versionInfo: VersionInfo,
        mediaURL: URL? = nil,
        primaryImageURL: URL? = nil,
        backdropImageURL: URL? = nil
    ) {
        // Make identity unique per episode-version to avoid SwiftUI collisions when multiple versions exist
        let baseId = episodeItem.id ?? UUID().uuidString
        self.id = baseId + ":" + versionInfo.versionId
        self.episodeItem = episodeItem
        self.versionInfo = versionInfo
        self.mediaURL = mediaURL
        self.primaryImageURL = primaryImageURL
        self.backdropImageURL = backdropImageURL
        self.episodeImageURL = nil
    }
}

// MARK: - Downloaded Movie

struct DownloadedMovie: Identifiable {
    let id: String
    let movieItem: BaseItemDto
    let versions: [DownloadedVersion]
    let primaryImageURL: URL?
    let backdropImageURL: URL?

    var displayTitle: String { movieItem.displayTitle }
    var hasMultipleVersions: Bool { versions.count > 1 }

    init(movieItem: BaseItemDto, versions: [DownloadedVersion], primaryImageURL: URL? = nil, backdropImageURL: URL? = nil) {
        self.id = movieItem.id ?? UUID().uuidString
        self.movieItem = movieItem
        self.versions = versions
        self.primaryImageURL = primaryImageURL
        self.backdropImageURL = backdropImageURL
    }
}

// MARK: - Downloaded Version

struct DownloadedVersion: Identifiable {
    let id: String
    let item: BaseItemDto
    let versionInfo: VersionInfo
    let mediaURL: URL?
    let primaryImageURL: URL?
    let backdropImageURL: URL?

    var displayName: String {
        if let mediaSourceId = versionInfo.mediaSourceId {
            // Try to get display name from media sources
            if let mediaSource = item.mediaSources?.first(where: { $0.id == mediaSourceId }) {
                return mediaSource.displayTitle ?? "Version \(mediaSourceId.prefix(8))"
            }
            return "Version \(mediaSourceId.prefix(8))"
        }
        return "Original Version"
    }

    init(item: BaseItemDto, versionInfo: VersionInfo, mediaURL: URL? = nil, primaryImageURL: URL? = nil, backdropImageURL: URL? = nil) {
        self.id = versionInfo.versionId
        self.item = item
        self.versionInfo = versionInfo
        self.mediaURL = mediaURL
        self.primaryImageURL = primaryImageURL
        self.backdropImageURL = backdropImageURL
    }
}

struct DownloadListView: View {

    // MARK: - State Properties

    @Router
    private var router

    @StateObject
    private var downloadManager = Container.shared.downloadManager()

    @State
    private var downloadedShows: [DownloadedShow] = []

    @State
    private var downloadedMovies: [DownloadedMovie] = []

    @State
    private var isLoading = true

    @State
    private var showingDeleteAlert = false

    @State
    private var showingDeleteAllAlert = false

    @State
    private var showingVersionSelectionAlert = false

    @State
    private var showToDelete: DownloadedShow?

    @State
    private var movieToDelete: DownloadedMovie?

    @State
    private var selectedMovie: DownloadedMovie?

    // MARK: - Dependencies

    private let logger = Logger.swiftfin()

    // MARK: - Computed Properties

    private var totalStorageUsed: String {
        guard let totalBytes = downloadManager.getTotalDownloadSize() else {
            return L10n.unknown
        }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    private var totalItemCount: Int {
        let episodeCount = downloadedShows.reduce(0) { $0 + $1.episodeCount }
        let movieVersionCount = downloadedMovies.reduce(0) { $0 + $1.versions.count }
        return episodeCount + movieVersionCount
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

                    if !downloadedShows.isEmpty || !downloadedMovies.isEmpty {
                        Text("\(totalItemCount) items • \(totalStorageUsed)")
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
                    // Downloaded Shows
                    ForEach(downloadedShows) { show in
                        DownloadedShowRow(
                            show: show,
                            downloadManager: downloadManager,
                            onTap: { handleShowTap(show) },
                            onDelete: { deleteDownloadedShow(show) }
                        )
                    }

                    // Downloaded Movies
                    ForEach(downloadedMovies) { movie in
                        DownloadedMovieRow(
                            movie: movie,
                            downloadManager: downloadManager,
                            onTap: { handleMovieTap(movie) },
                            onDelete: { deleteDownloadedMovie(movie) }
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
                } else if downloadedShows.isEmpty && downloadedMovies.isEmpty {
                    emptyView
                } else {
                    contentView
                }
            }
            .navigationTitle(L10n.downloads)
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete Download", isPresented: $showingDeleteAlert) {
                Button(L10n.cancel, role: .cancel) {
                    showToDelete = nil
                    movieToDelete = nil
                }
                Button(L10n.delete, role: .destructive) {
                    confirmDelete()
                }
            } message: {
                if let showToDelete = showToDelete {
                    Text("Are you sure you want to delete '\(showToDelete.displayTitle)' and all its episodes?")
                } else if let movieToDelete = movieToDelete {
                    Text("Are you sure you want to delete '\(movieToDelete.displayTitle)'?")
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
            .alert("Select Version", isPresented: $showingVersionSelectionAlert) {
                if let selectedMovie = selectedMovie {
                    ForEach(selectedMovie.versions, id: \.id) { version in
                        Button(version.displayName) {
                            playMovieVersion(version)
                        }
                    }
                    Button(L10n.cancel, role: .cancel) {
                        self.selectedMovie = nil
                    }
                }
            } message: {
                if let selectedMovie = selectedMovie {
                    Text("Select which version of '\(selectedMovie.displayTitle)' to play:")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !downloadedShows.isEmpty || !downloadedMovies.isEmpty {
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
        logger.info("Loading downloaded items from filesystem")

        // Get all downloaded item IDs from filesystem
        let downloadedItemIds = downloadManager.getDownloadedItemIds()
        logger.info("Found \(downloadedItemIds.count) downloaded item folders")

        var showsDict: [String: (seriesItem: BaseItemDto, episodes: [DownloadedEpisode])] = [:]
        var moviesArray: [DownloadedMovie] = []

        for itemId in downloadedItemIds {
            // Check if this is a series folder by looking for season subfolders
            let itemPath = URL.downloads.appendingPathComponent(itemId)

            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: itemPath.path)
                let seasonFolders = contents.filter { $0.hasPrefix("Season-") }

                if !seasonFolders.isEmpty {
                    // This is a series folder - load episodes from all seasons
                    logger.info("Found series folder: \(itemId) with \(seasonFolders.count) seasons")

                    var allEpisodes: [DownloadedEpisode] = []
                    var seriesItem: BaseItemDto?

                    for seasonFolder in seasonFolders.sorted() {
                        let seasonPath = itemPath.appendingPathComponent(seasonFolder)
                        let seasonMetadataFile = seasonPath.appendingPathComponent("metadata.json")

                        if let seasonData = FileManager.default.contents(atPath: seasonMetadataFile.path),
                           let seasonMetadata = try? JSONDecoder().decode(DownloadMetadata.self, from: seasonData)
                        {

                            logger.debug("Processing season: \(seasonFolder) with \(seasonMetadata.versions.count) versions")

                            // For each version in this season, try to load the episode from media files
                            for versionInfo in seasonMetadata.versions {
                                // Try to find the media file for this version
                                do {
                                    let _ = try FileManager.default.contentsOfDirectory(atPath: seasonPath.path)

                                    // Look for media file matching this version
                                    var episodeItem: BaseItemDto?

                                    // Prefer per-episode metadata when available
                                    if let epId = versionInfo.episodeId, let epItem = seasonMetadata.episodes?[epId] {
                                        episodeItem = epItem
                                    } else if let inferredId = inferEpisodeId(in: seasonPath, versionInfo: versionInfo),
                                              let epItem = seasonMetadata.episodes?[inferredId]
                                    {
                                        episodeItem = epItem
                                    } else if let templateItem = seasonMetadata.item, templateItem.type == .episode {
                                        // Fallback to template for backward compatibility
                                        episodeItem = templateItem
                                    }

                                    // If we have episode item data, create DownloadedEpisode
                                    if let episodeItem = episodeItem {
                                        // Create series item from first episode if we don't have it yet
                                        if seriesItem == nil {
                                            seriesItem = createSeriesItemFromEpisode(episodeItem)
                                        }

                                        let mediaURL = getMediaURL(for: itemId, versionInfo: versionInfo)
                                        let primaryImageURL = getPrimaryImageURL(for: itemId, item: episodeItem)
                                        let backdropImageURL = getBackdropImageURL(for: itemId, item: episodeItem)

                                        let downloadedEpisode = DownloadedEpisode(
                                            episodeItem: episodeItem,
                                            versionInfo: versionInfo,
                                            mediaURL: mediaURL,
                                            primaryImageURL: primaryImageURL,
                                            backdropImageURL: backdropImageURL
                                        )

                                        allEpisodes.append(downloadedEpisode)
                                    }
                                } catch {
                                    logger.warning("Failed to read season folder contents: \(error)")
                                }
                            }
                        }
                    }

                    // Add series to shows dictionary if we found episodes
                    if let seriesItem = seriesItem, !allEpisodes.isEmpty {
                        showsDict[itemId] = (seriesItem: seriesItem, episodes: allEpisodes)
                        logger.info("Loaded series: \(seriesItem.displayTitle) with \(allEpisodes.count) episodes")
                    }

                } else {
                    // This might be a movie or individual item - handle with existing logic
                    guard let metadata = downloadManager.getDownloadMetadata(for: itemId),
                          let item = metadata.item
                    else {
                        logger.warning("No metadata or item found for downloaded item: \(itemId)")
                        continue
                    }

                    // Process based on item type
                    switch item.type {
                    case .episode:
                        // This is an individual episode (legacy structure) - group by series
                        if let seriesId = item.seriesID {
                            // Create series item if we don't have it yet
                            if showsDict[seriesId] == nil {
                                // Create a basic series item from episode data
                                let seriesItem = createSeriesItemFromEpisode(item)
                                showsDict[seriesId] = (seriesItem: seriesItem, episodes: [])
                            }

                            // Process each version of this episode
                            for versionInfo in metadata.versions {
                                let mediaURL = getMediaURL(for: itemId, versionInfo: versionInfo)
                                let primaryImageURL = getPrimaryImageURL(for: itemId, item: item)
                                let backdropImageURL = getBackdropImageURL(for: itemId, item: item)

                                let downloadedEpisode = DownloadedEpisode(
                                    episodeItem: item,
                                    versionInfo: versionInfo,
                                    mediaURL: mediaURL,
                                    primaryImageURL: primaryImageURL,
                                    backdropImageURL: backdropImageURL
                                )

                                showsDict[seriesId]?.episodes.append(downloadedEpisode)
                            }
                        } case .movie:
                        // Handle movies
                        var downloadedVersions: [DownloadedVersion] = []

                        for versionInfo in metadata.versions {
                            let mediaURL = getMediaURL(for: itemId, versionInfo: versionInfo)
                            let primaryImageURL = getPrimaryImageURL(for: itemId, item: item)
                            let backdropImageURL = getBackdropImageURL(for: itemId, item: item)

                            let downloadedVersion = DownloadedVersion(
                                item: item,
                                versionInfo: versionInfo,
                                mediaURL: mediaURL,
                                primaryImageURL: primaryImageURL,
                                backdropImageURL: backdropImageURL
                            )

                            downloadedVersions.append(downloadedVersion)
                        }

                        if !downloadedVersions.isEmpty {
                            let primaryImageURL = getPrimaryImageURL(for: itemId, item: item)
                            let backdropImageURL = getBackdropImageURL(for: itemId, item: item)

                            let downloadedMovie = DownloadedMovie(
                                movieItem: item,
                                versions: downloadedVersions,
                                primaryImageURL: primaryImageURL,
                                backdropImageURL: backdropImageURL
                            )

                            moviesArray.append(downloadedMovie)
                            logger.info("Loaded movie: \(item.displayTitle) with \(downloadedVersions.count) versions")
                        }

                    default:
                        logger.warning("Unsupported item type for downloads: \(item.type?.rawValue ?? "nil")")
                    }
                }
            } catch {
                logger.warning("Failed to read contents of download folder \(itemId): \(error)")
            }
        }

        // Convert shows dictionary to array and add series images
        var showsArray: [DownloadedShow] = []
        for (seriesId, seriesData) in showsDict {
            let primaryImageURL = getSeriesPrimaryImageURL(for: seriesId)
            let backdropImageURL = getSeriesBackdropImageURL(for: seriesId)

            let downloadedShow = DownloadedShow(
                seriesItem: seriesData.seriesItem,
                episodes: seriesData.episodes.sorted {
                    // Sort episodes by season and episode number
                    if let season1 = $0.seasonNumber, let season2 = $1.seasonNumber {
                        if season1 != season2 {
                            return season1 < season2
                        }
                    }
                    if let ep1 = $0.episodeNumber, let ep2 = $1.episodeNumber {
                        return ep1 < ep2
                    }
                    return $0.displayTitle < $1.displayTitle
                },
                primaryImageURL: primaryImageURL,
                backdropImageURL: backdropImageURL
            )

            showsArray.append(downloadedShow)
            logger.info("Loaded show: \(seriesData.seriesItem.displayTitle) with \(seriesData.episodes.count) episodes")
        }

        // Sort arrays
        downloadedShows = showsArray.sorted { $0.displayTitle < $1.displayTitle }
        downloadedMovies = moviesArray.sorted { $0.displayTitle < $1.displayTitle }

        isLoading = false

        let totalEpisodes = downloadedShows.reduce(0) { $0 + $1.episodeCount }
        let totalMovieVersions = downloadedMovies.reduce(0) { $0 + $1.versions.count }
        logger
            .info(
                "Loaded \(downloadedShows.count) shows with \(totalEpisodes) episodes and \(downloadedMovies.count) movies with \(totalMovieVersions) versions"
            )
    }

    private func createSeriesItemFromEpisode(_ episode: BaseItemDto) -> BaseItemDto {
        // Create a basic series item using available episode information
        var seriesItem = BaseItemDto()
        seriesItem.id = episode.seriesID
        seriesItem.name = episode.seriesName
        seriesItem.type = .series

        // Copy over relevant properties if available
        seriesItem.overview = episode.overview
        seriesItem.productionYear = episode.productionYear

        return seriesItem
    }

    // MARK: - File URL Helpers

    private func getMediaURL(for itemId: String, versionInfo: VersionInfo) -> URL? {
        let downloadPath = URL.downloads.appendingPathComponent(itemId)

        do {
            // For episodes, check season folders
            if let enumerator = FileManager.default.enumerator(
                at: downloadPath,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) {
                for case let url as URL in enumerator {
                    let filename = url.lastPathComponent

                    // Check for version-specific files first
                    if let mediaSourceId = versionInfo.mediaSourceId {
                        if filename.contains(mediaSourceId) && !filename.contains("metadata") {
                            return url
                        }
                    }

                    // Fallback to generic media files
                    if filename.hasPrefix("Media.") || filename.contains(itemId) {
                        return url
                    }
                }
            }
        } catch {
            logger.warning("Error finding media file for item \(itemId): \(error)")
        }

        return nil
    }

    private func getPrimaryImageURL(for itemId: String, item: BaseItemDto) -> URL? {
        getImageURL(for: itemId, item: item, imageName: "Primary")
    }

    private func getBackdropImageURL(for itemId: String, item: BaseItemDto) -> URL? {
        getImageURL(for: itemId, item: item, imageName: "Backdrop")
    }

    private func getSeriesPrimaryImageURL(for seriesId: String) -> URL? {
        let downloadPath = URL.downloads.appendingPathComponent(seriesId)
        let imagesFolder = downloadPath.appendingPathComponent("Images")

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: imagesFolder.path)
            // Look for series-specific primary image pattern: Series-[seriesId]-Primary.*
            if let imageFile = contents.first(where: { $0.hasPrefix("Series-\(seriesId)-Primary") }) {
                return imagesFolder.appendingPathComponent(imageFile)
            }
        } catch {
            // Images folder doesn't exist, that's okay
            logger.debug("No Images folder found for series: \(seriesId)")
        }

        return nil
    }

    private func getSeriesBackdropImageURL(for seriesId: String) -> URL? {
        let downloadPath = URL.downloads.appendingPathComponent(seriesId)
        let imagesFolder = downloadPath.appendingPathComponent("Images")

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: imagesFolder.path)
            // Look for series-specific backdrop image pattern: Series-[seriesId]-Backdrop.*
            if let imageFile = contents.first(where: { $0.hasPrefix("Series-\(seriesId)-Backdrop") }) {
                return imagesFolder.appendingPathComponent(imageFile)
            }
        } catch {
            // Images folder doesn't exist, that's okay
            logger.debug("No Images folder found for series: \(seriesId)")
        }

        return nil
    }

    private func getImageURL(for itemId: String, item: BaseItemDto, imageName: String) -> URL? {
        // This method is used for individual episodes in the series context
        // Episodes are stored under series folders, so we need to use the series structure

        // For episodes, use the series folder structure
        if item.type == .episode, let seriesId = item.seriesID {
            let seriesPath = URL.downloads.appendingPathComponent(seriesId)

            // 1. First try episode-specific images in season folder
            if let seasonNumber = item.parentIndexNumber, let episodeId = item.id {
                let seasonFolder = seriesPath.appendingPathComponent("Season-\(String(format: "%02d", seasonNumber))")
                let seasonImagesFolder = seasonFolder.appendingPathComponent("Images")

                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: seasonImagesFolder.path)
                    // Look for episode-specific image: Episode-[episodeId]-{Primary|Backdrop}.*
                    if let imageFile = contents.first(where: { $0.hasPrefix("Episode-\(episodeId)-\(imageName)") }) {
                        return seasonImagesFolder.appendingPathComponent(imageFile)
                    }

                    // 2. Fallback to season-specific images in same folder
                    if let seasonId = item.seasonID {
                        if let imageFile = contents.first(where: { $0.hasPrefix("Season-\(seasonId)-\(imageName)") }) {
                            return seasonImagesFolder.appendingPathComponent(imageFile)
                        }
                    }
                } catch {
                    logger.debug("No season Images folder found for episode: \(item.displayTitle)")
                }
            }

            // 3. Fallback to series-level images
            let seriesImagesFolder = seriesPath.appendingPathComponent("Images")
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: seriesImagesFolder.path)
                // Look for series-specific image: Series-[seriesId]-{Primary|Backdrop}.*
                if let imageFile = contents.first(where: { $0.hasPrefix("Series-\(seriesId)-\(imageName)") }) {
                    return seriesImagesFolder.appendingPathComponent(imageFile)
                }
            } catch {
                logger.debug("No series Images folder found for series: \(seriesId)")
            }
        } else {
            // For movies, use the simple naming pattern in the item's own folder
            let downloadPath = URL.downloads.appendingPathComponent(itemId)
            let imagesFolder = downloadPath.appendingPathComponent("Images")

            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: imagesFolder.path)
                // Look for simple movie image pattern: {Primary|Backdrop}.*
                if let imageFile = contents.first(where: { $0.hasPrefix(imageName) }) {
                    return imagesFolder.appendingPathComponent(imageFile)
                }
            } catch {
                logger.debug("No Images folder found for movie: \(itemId)")
            }
        }

        return nil
    }

    // Try to infer the episodeId from filenames like "[episodeId]-[versionId].ext" within a Season-XX folder
    private func inferEpisodeId(in seasonFolder: URL, versionInfo: VersionInfo) -> String? {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: seasonFolder.path)
            let candidates = contents.filter { filename in
                guard !filename.contains("metadata") else { return false }
                if let msid = versionInfo.mediaSourceId, filename.contains(msid) { return true }
                return filename.contains("-")
            }
            if let match = candidates.first, let dash = match.firstIndex(of: "-") {
                return String(match[..<dash])
            }
        } catch {
            logger.debug("Failed to infer episode id from season folder: \(error)")
        }
        return nil
    }

    @MainActor
    private func refreshDownloads() async {
        logger.info("Pull-to-refresh triggered")
        loadDownloadedItems()
    }

    private func deleteDownloadedShow(_ show: DownloadedShow) {
        logger.info("User requested to delete show: \(show.displayTitle)")
        showToDelete = show
        showingDeleteAlert = true
    }

    private func deleteDownloadedMovie(_ movie: DownloadedMovie) {
        logger.info("User requested to delete movie: \(movie.displayTitle)")
        movieToDelete = movie
        showingDeleteAlert = true
    }

    private func confirmDelete() {
        if let showToDelete = showToDelete {
            logger.info("Confirming deletion of show: \(showToDelete.displayTitle)")

            let success = downloadManager.deleteDownloadedMedia(itemId: showToDelete.id)

            if success {
                downloadedShows.removeAll { $0.id == showToDelete.id }
                logger.info("Successfully deleted show from UI")
            } else {
                logger.error("Failed to delete show for item: \(showToDelete.id)")
            }

            self.showToDelete = nil

        } else if let movieToDelete = movieToDelete {
            logger.info("Confirming deletion of movie: \(movieToDelete.displayTitle)")

            let success = downloadManager.deleteDownloadedMedia(itemId: movieToDelete.id)

            if success {
                downloadedMovies.removeAll { $0.id == movieToDelete.id }
                logger.info("Successfully deleted movie from UI")
            } else {
                logger.error("Failed to delete movie for item: \(movieToDelete.id)")
            }

            self.movieToDelete = nil
        }
    }

    private func confirmDeleteAll() {
        logger.info("Confirming deletion of all downloads")
        downloadManager.deleteAllDownloadedMedia()
        downloadedShows.removeAll()
        downloadedMovies.removeAll()
        logger.info("Successfully deleted all downloads from UI")
    }

    private func handleShowTap(_ show: DownloadedShow) {
        logger.info("User tapped on show: \(show.displayTitle)")
        router.route(to: .itemDownloadList(item: show.seriesItem))
    }

    private func handleMovieTap(_ movie: DownloadedMovie) {
        if movie.hasMultipleVersions {
            selectedMovie = movie
            showingVersionSelectionAlert = true
        } else {
            // Single version - play directly
            if let version = movie.versions.first {
                playMovieVersion(version)
            }
        }
    }

    private func playMovieVersion(_ downloadedVersion: DownloadedVersion) {
        logger.warning("Player will be implemented later")
    }
}

// MARK: - Downloaded Show Row

struct DownloadedShowRow: View {

    // MARK: - Properties

    let show: DownloadedShow
    let downloadManager: DownloadManager
    let onTap: () -> Void
    let onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail
                ImageView(show.primaryImageURL ?? show.backdropImageURL)
                    .pipeline(.Swiftfin.local)
                    .failure {
                        Rectangle()
                            .foregroundStyle(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "tv")
                            }
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Content info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(show.displayTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(2)

                        Spacer()

                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }

                    if let overview = show.seriesItem.overview {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }

                    // Metadata badges
                    HStack {
                        if let year = show.seriesItem.productionYear {
                            Text(String(year))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Text("\(show.episodeCount) episodes")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        if show.seasons.count > 1 {
                            Text("\(show.seasons.count) seasons")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Spacer()
                    }
                }
            }
            .padding()
            .background(.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Downloaded Movie Row

struct DownloadedMovieRow: View {

    // MARK: - Properties

    let movie: DownloadedMovie
    let downloadManager: DownloadManager
    let onTap: () -> Void
    let onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail
                ImageView(movie.primaryImageURL ?? movie.backdropImageURL)
                    .pipeline(.Swiftfin.local)
                    .failure {
                        Rectangle()
                            .foregroundStyle(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "film")
                            }
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Content info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(movie.displayTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(2)

                        Spacer()

                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }

                    if let overview = movie.movieItem.overview {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }

                    // Metadata badges
                    HStack {
                        if let year = movie.movieItem.productionYear {
                            Text(String(year))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        if let runtime = movie.movieItem.runTimeTicks {
                            let minutes = runtime / 600_000_000 // Convert ticks to minutes
                            Text("\(minutes)m")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                        }

                        if movie.hasMultipleVersions {
                            Text("\(movie.versions.count) versions")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Spacer()
                    }
                }
            }
            .padding()
            .background(.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
