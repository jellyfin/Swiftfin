//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class SubtitleEditorViewModel: ViewModel, Stateful, Eventful {

    // MARK: - Events

    enum Event: Equatable {
        case deleted
        case uploaded
        case error(ErrorMessage)
    }

    // MARK: - Action

    enum Action: Equatable {
        case cancel
        case search(language: String? = nil, isPerfectMatch: Bool? = nil)
        case set(Set<String>)
        case upload(UploadSubtitleDto)
        case delete(Set<MediaStream>)
    }

    // MARK: - Background State

    enum BackgroundState: Hashable {
        case updating
        case searching
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case content
        case error(ErrorMessage)
    }

    @Published
    var state: State = .initial
    @Published
    var backgroundStates: Set<BackgroundState> = []

    // MARK: - Published Item

    @Published
    var item: BaseItemDto
    @Published
    var internalSubtitles: [MediaStream]
    @Published
    var externalSubtitles: [MediaStream]
    @Published
    var searchResults: [RemoteSubtitleInfo] = []

    // MARK: Event Variables

    private var subtitleTask: AnyCancellable?
    private var searchTask: AnyCancellable?
    private var searchQuery: CurrentValueSubject<(language: String, isPerfectMatch: Bool?), Never> = .init(("", nil))
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .eraseToAnyPublisher()
    }

    // MARK: - Initializer

    init(item: BaseItemDto) {
        self.item = item

        let subtitles = (item.mediaSources ?? [])
            .compactMap(\.subtitleStreams)
            .flattened()
            .grouped(by: \.isExternal)

        self.internalSubtitles = subtitles[false] ?? []
        self.externalSubtitles = subtitles[true] ?? []

        super.init()

        /// Setup debounced search
        searchQuery
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] searchParams in
                guard let self, searchParams.language.isNotEmpty else { return }

                self.searchTask?.cancel()
                self.search(language: searchParams.language, isPerfectMatch: searchParams.isPerfectMatch)
            }
            .store(in: &cancellables)
    }

    // MARK: - Respond

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            subtitleTask?.cancel()
            backgroundStates.remove(.updating)
            eventSubject.send(.error(ErrorMessage(L10n.taskCancelled)))

            return state

        case let .delete(mediaStreams):
            subtitleTask?.cancel()

            subtitleTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.insert(.updating)
                    }

                    try await self.deleteSubtitles(mediaStreams: mediaStreams)
                    try await self.refreshItem()

                    await MainActor.run {
                        self.backgroundStates.remove(.updating)
                        self.eventSubject.send(.deleted)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self.state = .error(ErrorMessage(error.localizedDescription))
                        self.eventSubject.send(.error(ErrorMessage(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .initial

        case let .upload(subtitle):
            subtitleTask?.cancel()

            subtitleTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.insert(.updating)
                    }

                    try await self.uploadSubtitle(subtitle: subtitle)
                    try await self.refreshItem()

                    await MainActor.run {
                        self.backgroundStates.remove(.updating)
                        self.eventSubject.send(.uploaded)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self.state = .error(ErrorMessage(error.localizedDescription))
                        self.eventSubject.send(.error(ErrorMessage(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .initial

        case let .search(language, isPerfectMatch):
            let searchLanguage = language ?? ""
            searchQuery.send((language: searchLanguage, isPerfectMatch: isPerfectMatch))
            return .initial

        case let .set(subtitles):
            subtitleTask?.cancel()

            subtitleTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.insert(.updating)
                    }

                    try await self.setSubtitles(subtitles: subtitles)
                    try await self.refreshItem()

                    await MainActor.run {
                        self.backgroundStates.remove(.updating)
                        self.eventSubject.send(.uploaded)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self.state = .error(ErrorMessage(error.localizedDescription))
                        self.eventSubject.send(.error(ErrorMessage(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .initial
        }
    }

    // MARK: - Search

    private func search(language: String, isPerfectMatch: Bool?) {
        searchTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                await MainActor.run {
                    _ = self.backgroundStates.insert(.searching)
                }
                let results = try await self.searchSubtitles(
                    language: language,
                    isPerfectMatch: isPerfectMatch
                )

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.searchResults = results
                    self.backgroundStates.remove(.searching)
                    self.state = .content
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.state = .error(ErrorMessage(error.localizedDescription))
                    self.eventSubject.send(.error(ErrorMessage(error.localizedDescription)))
                }
            }
        }
        .asAnyCancellable()
    }

    // MARK: - Delete Subtitle

    private func deleteSubtitles(mediaStreams: Set<MediaStream>) async throws {
        guard let itemID = item.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        /// Extract non-nil indexes from mediaStreams
        let indices = mediaStreams.compactMap(\.index)
            .sorted(by: >)

        /// Track successfully deleted indexes
        var deletedIndices = Set<Int>()

        for index in indices {
            let request = Paths.deleteSubtitle(itemID: itemID, index: index)
            do {
                _ = try await userSession.client.send(request)
                deletedIndices.insert(index)
            } catch {
                throw ErrorMessage(L10n.failedDeletionAtIndexError(
                    index,
                    error
                ))
            }
        }
    }

    // MARK: - Search for Subtitles

    private func searchSubtitles(language: String, isPerfectMatch: Bool? = nil) async throws -> [RemoteSubtitleInfo] {
        guard let itemID = item.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        let request = Paths.searchRemoteSubtitles(
            itemID: itemID,
            language: language,
            isPerfectMatch: isPerfectMatch
        )
        let results = try await userSession.client.send(request)

        return results.value
    }

    // MARK: - Set Remote Subtitles

    private func setSubtitles(subtitles: Set<String>) async throws {
        guard let itemID = item.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for subtitleID in subtitles {
                group.addTask {
                    let request = Paths.downloadRemoteSubtitles(itemID: itemID, subtitleID: subtitleID)
                    _ = try await self.userSession.client.send(request)
                }
            }

            try await group.waitForAll()
        }
    }

    // MARK: - Subtitle Upload Logic

    private func uploadSubtitle(subtitle: UploadSubtitleDto) async throws {
        guard let itemID = item.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        let request = Paths.uploadSubtitle(itemID: itemID, subtitle)
        _ = try await userSession.client.send(request)
    }

    // MARK: - Refresh Item

    private func refreshItem() async throws {
        guard let itemID = item.id else { return }

        await MainActor.run {
            _ = backgroundStates.insert(.updating)
        }

        let request = Paths.getItem(
            itemID: itemID,
            userID: userSession.user.id
        )

        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.item = response.value

            /// Important: Subtitle track indexes change sporadically
            /// Extract subtitle streams from all media sources
            let subtitles = (item.mediaSources ?? [])
                .compactMap(\.subtitleStreams)
                .flattened()
                .grouped(by: \.isExternal)

            self.internalSubtitles = subtitles[false] ?? []
            self.externalSubtitles = subtitles[true] ?? []

            _ = backgroundStates.remove(.updating)
            Notifications[.itemMetadataDidChange].post(item)
        }
    }
}
