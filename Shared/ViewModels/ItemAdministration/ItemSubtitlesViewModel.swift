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
        case _actuallySearch(isPerfectMatch: Bool)
        case delete(Set<MediaStream>)
        case refresh
        case search(isPerfectMatch: Bool)
        case set(Set<String>)
        case upload(file: URL, isForced: Bool, isHearingImpaired: Bool)

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.initial, then: .content)
            case ._actuallySearch, .search:
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
    private(set) var internalSubtitles: [MediaStream]
    @Published
    private(set) var externalSubtitles: [MediaStream]
    @Published
    private(set) var results: [RemoteSubtitleInfo] = []

    /// Default to user's language
    @Published
    var language: String? = Locale.current.language.languageCode?.identifier(.alpha3)

    let item: BaseItemDto

    private var query: CurrentValueSubject<Bool, Never> = .init(false)

    init(item: BaseItemDto) {
        self.item = item

        let subtitles = (item.mediaSources ?? [])
            .compactMap(\.subtitleStreams)
            .flattened()

        self.internalSubtitles = subtitles.filter { $0.isExternal == false }
        self.externalSubtitles = subtitles.filter { $0.isExternal == true }

        super.init()

        $language
            .combineLatest(query)
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates(by: { $0.0 == $1.0 && $0.1 == $1.1 })
            .sink { [weak self] _, isPerfectMatch in
                self?._actuallySearch(isPerfectMatch: isPerfectMatch)
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
    private func _search(_ isPerfectMatch: Bool) async throws {
        query.send(isPerfectMatch)

        await cancel()
    }

    @Function(\Action.Cases._actuallySearch)
    private func __actuallySearch(_ isPerfectMatch: Bool) async throws {
        guard let itemID = item.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        // Avoids errors when `None` is selected
        guard let language, language.isNotEmpty else {
            results = []
            return
        }

        let request = Paths.searchRemoteSubtitles(
            itemID: itemID,
            language: language,
            isPerfectMatch: isPerfectMatch
        )
        let results = try await userSession.client.send(request)

        self.results = results.value
    }

    @Function(\Action.Cases.set)
    private func _set(_ subtitles: Set<String>) async throws {
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

        try await refreshItem(sendNotification: true)

        events.send(.uploaded)
    }

    @Function(\Action.Cases.upload)
    private func _upload(_ file: URL, _ isForced: Bool, _ isHearingImpaired: Bool) async throws {

        guard let itemID = item.id, let language, language.isNotEmpty else {
            throw ErrorMessage(L10n.unknownError)
        }

        guard file.isFileURL, let format = SubtitleFormat(url: file) else {
            throw ErrorMessage(L10n.invalidFormat)
        }

        let data = try Data(contentsOf: file)

        let subtitle = UploadSubtitleDto(
            data: data.base64EncodedString(),
            format: format.fileExtension,
            isForced: isForced,
            isHearingImpaired: isHearingImpaired,
            language: language
        )

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
