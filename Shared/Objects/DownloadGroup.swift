//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// MARK: - Download Group Models

/// Represents a hierarchical group of downloads
enum DownloadGroup: Identifiable, Hashable {
    case movie(DownloadTask)
    case series(SeriesGroup)
    case standalone(DownloadTask) // For standalone episodes, audio, etc.

    var id: String {
        switch self {
        case let .movie(task):
            return task.item.id ?? UUID().uuidString
        case let .series(group):
            return group.id
        case let .standalone(task):
            return task.item.id ?? UUID().uuidString
        }
    }

    var displayTitle: String {
        switch self {
        case let .movie(task):
            return task.item.displayTitle
        case let .series(group):
            return group.displayTitle
        case let .standalone(task):
            return task.item.displayTitle
        }
    }

    var totalStorageSize: Int64 {
        switch self {
        case let .movie(task):
            return task.item.downloadFolder.flatMap { URL.folderSize(at: $0) } ?? 0
        case let .series(group):
            return group.totalStorageSize
        case let .standalone(task):
            return task.item.downloadFolder.flatMap { URL.folderSize(at: $0) } ?? 0
        }
    }

    var itemCount: Int {
        switch self {
        case .movie, .standalone:
            return 1
        case let .series(group):
            return group.itemCount
        }
    }
}

/// Represents a series with its seasons and episodes
struct SeriesGroup: Identifiable, Hashable {
    let id: String
    let displayTitle: String
    let overview: String?
    let imageURL: URL?
    let seriesTask: DownloadTask? // Optional series-level download task
    var seasons: [SeasonGroup]

    init(seriesID: String, displayTitle: String, overview: String?, imageURL: URL?, seriesTask: DownloadTask? = nil) {
        self.id = seriesID
        self.displayTitle = displayTitle
        self.overview = overview
        self.imageURL = imageURL
        self.seriesTask = seriesTask
        self.seasons = []
    }

    var totalStorageSize: Int64 {
        var total: Int64 = 0

        // Add series-level storage if it exists
        if let seriesTask = seriesTask,
           let downloadFolder = seriesTask.item.downloadFolder,
           let folderSize = URL.folderSize(at: downloadFolder)
        {
            total += folderSize
        }

        // Add all seasons' storage
        for season in seasons {
            total += season.totalStorageSize
        }

        return total
    }

    var itemCount: Int {
        seasons.reduce(0) { $0 + $1.itemCount } + (seriesTask != nil ? 1 : 0)
    }
}

/// Represents a season with its episodes
struct SeasonGroup: Identifiable, Hashable {
    let id: String
    let seriesID: String
    let displayTitle: String
    let indexNumber: Int?
    let overview: String?
    let imageURL: URL?
    var episodes: [EpisodeGroup]

    init(seasonID: String, seriesID: String, displayTitle: String, indexNumber: Int?, overview: String?, imageURL: URL?) {
        self.id = seasonID
        self.seriesID = seriesID
        self.displayTitle = displayTitle
        self.indexNumber = indexNumber
        self.overview = overview
        self.imageURL = imageURL
        self.episodes = []
    }

    var totalStorageSize: Int64 {
        episodes.reduce(0) { $0 + $1.storageSize }
    }

    var itemCount: Int {
        episodes.count
    }
}

/// Represents an episode download
struct EpisodeGroup: Identifiable, Hashable {
    let id: String
    let seriesID: String
    let seasonID: String?
    let downloadTask: DownloadTask

    init(downloadTask: DownloadTask) {
        self.id = downloadTask.item.id ?? UUID().uuidString
        self.seriesID = downloadTask.item.seriesID ?? ""
        self.seasonID = downloadTask.item.seasonID
        self.downloadTask = downloadTask
    }

    var displayTitle: String {
        downloadTask.item.displayTitle
    }

    var storageSize: Int64 {
        guard let downloadFolder = downloadTask.item.downloadFolder else { return 0 }
        return URL.folderSize(at: downloadFolder) ?? 0
    }
}

// MARK: - Helper Functions

// MARK: - Data Transformation

/// Transforms a flat array of DownloadTask into hierarchical DownloadGroup structure
func transformDownloadsToHierarchy(_ downloadTasks: [DownloadTask]) -> [DownloadGroup] {
    var seriesGroups: [String: SeriesGroup] = [:]
    var standaloneItems: [DownloadGroup] = []

    for task in downloadTasks {
        switch task.item.type {
        case .movie:
            standaloneItems.append(.movie(task))

        case .series:
            // Create or update series group
            let seriesID = task.item.id ?? UUID().uuidString
            if seriesGroups[seriesID] == nil {
                seriesGroups[seriesID] = SeriesGroup(
                    seriesID: seriesID,
                    displayTitle: task.item.displayTitle,
                    overview: task.item.overview,
                    imageURL: task.getImageURL(name: "Primary") ?? task.getImageURL(name: "Backdrop"),
                    seriesTask: task
                )
            }

        case .episode:
            guard let seriesID = task.item.seriesID else {
                // Episode without series ID becomes standalone
                standaloneItems.append(.standalone(task))
                continue
            }

            // Get or create series group
            if seriesGroups[seriesID] == nil {
                seriesGroups[seriesID] = SeriesGroup(
                    seriesID: seriesID,
                    displayTitle: task.item.seriesName ?? "Unknown Series",
                    overview: nil,
                    imageURL: task.getImageURL(name: "Primary") ?? task.getImageURL(name: "Backdrop")
                )
            }

            // Get or create season group
            let seasonID = task.item.seasonID ?? "unknown-season"
            let seasonDisplayTitle = task.item.seasonName ?? "Season \(task.item.parentIndexNumber ?? 1)"

            if let seasonIndex = seriesGroups[seriesID]!.seasons.firstIndex(where: { $0.id == seasonID }) {
                // Add episode to existing season
                let episodeGroup = EpisodeGroup(downloadTask: task)
                seriesGroups[seriesID]!.seasons[seasonIndex].episodes.append(episodeGroup)
            } else {
                // Create new season and add episode
                var newSeason = SeasonGroup(
                    seasonID: seasonID,
                    seriesID: seriesID,
                    displayTitle: seasonDisplayTitle,
                    indexNumber: task.item.parentIndexNumber,
                    overview: nil,
                    imageURL: task.getImageURL(name: "Primary") ?? task.getImageURL(name: "Backdrop")
                )

                let episodeGroup = EpisodeGroup(downloadTask: task)
                newSeason.episodes.append(episodeGroup)
                seriesGroups[seriesID]!.seasons.append(newSeason)
            }

        default:
            // Other types (audio, video, etc.) become standalone items
            standaloneItems.append(.standalone(task))
        }
    }

    // Sort seasons within each series by index number
    for seriesID in seriesGroups.keys {
        seriesGroups[seriesID]!.seasons.sort { season1, season2 in
            (season1.indexNumber ?? 0) < (season2.indexNumber ?? 0)
        }

        // Sort episodes within each season by index number
        for seasonIndex in seriesGroups[seriesID]!.seasons.indices {
            seriesGroups[seriesID]!.seasons[seasonIndex].episodes.sort { episode1, episode2 in
                (episode1.downloadTask.item.indexNumber ?? 0) < (episode2.downloadTask.item.indexNumber ?? 0)
            }
        }
    }

    // Convert to DownloadGroup array and sort
    var result: [DownloadGroup] = []

    // Add series groups (sorted by display title)
    let sortedSeriesGroups = seriesGroups.values.sorted { $0.displayTitle < $1.displayTitle }
    for seriesGroup in sortedSeriesGroups {
        result.append(.series(seriesGroup))
    }

    // Add standalone items (sorted by display title)
    let sortedStandaloneItems = standaloneItems.sorted { $0.displayTitle < $1.displayTitle }
    result.append(contentsOf: sortedStandaloneItems)

    return result
}
