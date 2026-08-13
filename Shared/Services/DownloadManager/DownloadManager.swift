//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import FactoryKit
import Foundation
import JellyfinAPI
import Logging

extension Container {
    var downloadManager: Factory<DownloadManager> {
        self { MainActor.assumeIsolated { DownloadManager() } }.shared
    }
}

@MainActor
final class DownloadManager: NSObject, ObservableObject {

    struct Active {
        let id: String
        let urlTask: URLSessionDownloadTask
    }

    static let libraryID = "downloads"

    let logger = Logger.swiftfin()

    @Published
    var tasks: [DownloadTask] = []

    var active: Active?
    var runningContainers: Set<String> = []
    private var lastPersistedAt: Date?

    lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "org.jellyfin.swiftfin.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = false
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    var userSession: UserSession? {
        Container.shared.currentUserSession()
    }

    var currentUserID: String? {
        userSession?.user.id
    }

    override init() {
        super.init()
        load()
        _ = urlSession
        Task { @MainActor in
            self.advanceQueue()
        }
    }

    // MARK: - Lookup

    func task(id: String) -> DownloadTask? {
        tasks.first { $0.id == id }
    }

    func allItems() -> [BaseItemDto] {
        tasks.map(\.item)
    }

    func localQueryFilters() -> (QueryFilters, QueryFiltersLegacy) {
        let items = tasks.filter(\.isCompleted).map(\.item)

        let audioLanguages = Set(items.flatMap(\.audioStreams).compactMap(\.language))
        let genres = Set(items.compactMap(\.genres).flatMap(\.self))
        let officialRatings = Set(items.compactMap(\.officialRating))
        let subtitleLanguages = Set(items.flatMap(\.subtitleStreams).compactMap(\.language))
        let tags = Set(items.compactMap(\.tags).flatMap(\.self))
        let years = Set(items.compactMap(\.productionYear))

        let queryFilters = QueryFilters(
            audioLanguages: audioLanguages.map(languagePair),
            genres: genres.sorted().map { NameIDPair(name: $0) },
            subtitleLanguages: subtitleLanguages.map(languagePair),
            tags: tags.sorted()
        )

        let legacyQueryFilters = QueryFiltersLegacy(
            genres: genres.sorted(),
            officialRatings: officialRatings.sorted(),
            tags: tags.sorted(),
            years: years.sorted()
        )

        return (queryFilters, legacyQueryFilters)
    }

    private func languagePair(_ code: String) -> NameValuePair {
        NameValuePair(
            name: Locale.current.localizedString(forLanguageCode: code) ?? code,
            value: code
        )
    }

    func children(of id: String) -> [DownloadTask] {
        tasks.filter { $0.parentIDs.contains(id) }
    }

    func childItems(of id: String) -> [BaseItemDto] {
        children(of: id)
            .sorted { lhs, rhs in
                (lhs.item.indexNumber ?? .max, lhs.displayTitle) < (rhs.item.indexNumber ?? .max, rhs.displayTitle)
            }
            .map(\.item)
    }

    func topLevel() -> [DownloadTask] {
        let existingIDs = Set(tasks.map(\.id))
        return tasks.filter { task in
            !task.parentIDs.contains { existingIDs.contains($0) }
        }
    }

    func descendants(of id: String) -> [String] {
        var result: [String] = []
        var queue = children(of: id).map(\.id)
        while let next = queue.popLast() {
            result.append(next)
            queue.append(contentsOf: children(of: next).map(\.id))
        }
        return result
    }

    func isFullyCompleted(_ task: DownloadTask) -> Bool {
        guard task.isCompleted else { return false }
        return descendants(of: task.id).allSatisfy { id in
            tasks.first(where: { $0.id == id })?.isCompleted ?? true
        }
    }

    func displayProgress(for id: String) -> Double {
        guard let task = task(id: id) else { return 0 }

        if task.isContainer {
            let media = descendants(of: id)
                .compactMap { self.task(id: $0) }
                .filter { !$0.isContainer }

            guard media.isNotEmpty else { return task.isCompleted ? 1 : 0 }

            return Double(media.filter(\.isCompleted).count) / Double(media.count)
        }

        return task.progress
    }

    func taskPublisher(for id: String) -> AnyPublisher<DownloadTask?, Never> {
        $tasks
            .map { $0.first(where: { $0.id == id }) }
            .removeDuplicates(by: { $0?.state == $1?.state })
            .eraseToAnyPublisher()
    }

    // MARK: - Persistence

    private func load() {
        guard let userID = currentUserID else {
            tasks = []
            return
        }

        let stored = StoredValues[.Downloads.all(userID: userID)]

        let resurrected = stored.map { task -> DownloadTask in
            guard task.state == .downloading else { return task }
            // Media tasks may hold resume data, so pause instead of requeueing
            return task.mutating(\.state, with: task.isContainer ? .queued : .paused)
        }

        tasks = resurrected
        if resurrected != stored {
            persistTasks()
        }

        refreshContainerUnplayedCounts()
    }

    func persistTasks() {
        guard let userID = currentUserID else { return }
        StoredValues[.Downloads.all(userID: userID)] = tasks
    }

    func update(id: String, throttle: Bool = false, _ mutator: (inout DownloadTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        var task = tasks[index]
        mutator(&task)
        tasks[index] = task

        let now = Date()
        if throttle {
            if now.timeIntervalSince(lastPersistedAt ?? .distantPast) > 1.0 {
                lastPersistedAt = now
                persistTasks()
            }
        } else {
            lastPersistedAt = now
            persistTasks()
        }
    }
}
