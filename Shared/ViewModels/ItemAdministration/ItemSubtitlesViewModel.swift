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

@MainActor
@Stateful
final class ItemSubtitlesViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh
        case search
        case set(Set<String>)
        case upload(URL, isForced: Bool, isHearingImpaired: Bool)
        case delete(Set<MediaStream>)

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.initial, then: .content)
            case .search:
                .background(.searching)
            case .set, .upload, .delete:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case updating
        case searching
    }

    enum Event {
        case deleted
        case uploaded
    }

    enum State {
        case initial
        case content
        case error
    }

    @Published
    var item: BaseItemDto
    @Published
    var internalSubtitles: [MediaStream]
    @Published
    var externalSubtitles: [MediaStream]

    @Published
    var searchResults: [RemoteSubtitleInfo] = []

    /// Default to user's language & fallback to English
    @Published
    var language: String? = Locale.current.language.languageCode?.identifier(.alpha3)
    @Published
    var isPerfectMatch = false

    init(item: BaseItemDto) {
        self.item = item

        let subtitles = (item.mediaSources ?? [])
            .compactMap(\.subtitleStreams)
            .flattened()
            .grouped(by: \.isExternal)

        self.internalSubtitles = subtitles[false] ?? []
        self.externalSubtitles = subtitles[true] ?? []

        super.init()

        Publishers.CombineLatest($language, $isPerfectMatch)
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                guard let self else { return }
                self.search()
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        try await refreshItem(sendNotification: false)
    }

    private func refreshItem(sendNotification: Bool = false) async throws {
        let item = try await item.getFullItem(userSession: userSession, sendNotification: sendNotification)

        let subtitles = (item.mediaSources ?? [])
            .compactMap(\.subtitleStreams)
            .flattened()
            .grouped(by: \.isExternal)

        internalSubtitles = subtitles[false] ?? []
        externalSubtitles = subtitles[true] ?? []
    }

    @Function(\Action.Cases.search)
    private func _search() async throws {
        guard let itemID = item.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        // Avoids errors when `None` is selected
        guard let language, language.isNotEmpty else {
            searchResults = []
            return
        }

        let request = Paths.searchRemoteSubtitles(
            itemID: itemID,
            language: language,
            isPerfectMatch: isPerfectMatch
        )
        let results = try await userSession.client.send(request)

        self.searchResults = results.value
    }

    @Function(\Action.Cases.set)
    private func _set(_ subtitles: Set<String>) async throws {
        guard let itemID = item.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        let previousSubtitles = (item.mediaSources ?? [])
            .compactMap(\.subtitleStreams)
            .flattened()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for subtitleID in subtitles {
                group.addTask {
                    let request = Paths.downloadRemoteSubtitles(itemID: itemID, subtitleID: subtitleID)
                    _ = try await self.userSession.client.send(request)
                }
            }

            try await group.waitForAll()
        }

        try await refreshItem(sendNotification: true)

        events.send(.uploaded)
    }

    @Function(\Action.Cases.upload)
    private func _upload(_ fileURL: URL, _ isForced: Bool, _ isHearingImpaired: Bool) async throws {
        guard let itemID = item.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        guard let format = SubtitleFormat(url: fileURL) else {
            throw ErrorMessage(L10n.invalidFormat)
        }

        guard let language, language.isNotEmpty else {
            throw ErrorMessage(L10n.unknownError)
        }

        let data = try Data(contentsOf: fileURL)

        let subtitle = UploadSubtitleDto(
            data: data.base64EncodedString(),
            format: format.fileExtension,
            isForced: isForced,
            isHearingImpaired: isHearingImpaired,
            language: language
        )

        let previousSubtitles = (item.mediaSources ?? [])
            .compactMap(\.subtitleStreams)
            .flattened()

        let request = Paths.uploadSubtitle(itemID: itemID, subtitle)
        _ = try await userSession.client.send(request)

        try await refreshItem(sendNotification: true)

        events.send(.uploaded)
    }

    @Function(\Action.Cases.delete)
    private func _delete(_ mediaStreams: Set<MediaStream>) async throws {
        guard let itemID = item.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        let indices = mediaStreams.compactMap(\.index)
            .sorted(by: >)

        let previousSubtitles = (item.mediaSources ?? [])
            .compactMap(\.subtitleStreams)
            .flattened()

        for index in indices {
            let request = Paths.deleteSubtitle(itemID: itemID, index: index)
            do {
                _ = try await userSession.client.send(request)
            } catch {
                throw ErrorMessage(L10n.failedDeletionAtIndexError(index, error))
            }
        }

        try await refreshItem(sendNotification: true)

        events.send(.deleted)
    }
}
