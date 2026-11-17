//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@Observable
@StatefulObservable
final class ItemSubtitlesViewModel: ViewModel {

    @CasePathable
    enum Action {

        case delete(Set<MediaStream>)
        case refresh
        case search
        case set(Set<String>)
        case upload(file: URL, isForced: Bool, isHearingImpaired: Bool)

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
        case error
        case uploaded
    }

    enum State {

        case initial
        case content
        case error
    }

    private struct SearchOptions: Equatable, Sendable {

        let isPerfectMatch: Bool
        let language: String?
    }

    @ObservationIgnored
    private var searchObservationID: UUID?

    var isPerfectMatch = false {
        didSet {
            guard isPerfectMatch != oldValue else { return }

            core.cancel(action: \.search)
        }
    }

    private var itemStorage: ValueBox<ItemEntry>

    var language: String? = Locale.current.language.languageCode?.identifier(.alpha3) {
        didSet {
            guard language != oldValue else { return }

            core.cancel(action: \.search)
        }
    }

    private(set) var results: [RemoteSubtitleInfo] = []

    var externalSubtitles: [MediaStream] {
        subtitles.filter { $0.isExternal == true }
    }

    var internalSubtitles: [MediaStream] {
        subtitles.filter { $0.isExternal == false }
    }

    var item: BaseItemDto {
        itemStorage.value.snapshot
    }

    private var subtitles: [MediaStream] {
        (item.mediaSources ?? [])
            .compactMap(\.subtitleStreams)
            .flattened()
    }

    init(item: BaseItemDto) {
        self.itemStorage = .init(value: ItemEntry.resolve(item))
        super.init()
    }

    func observeSearchOptions() async {
        guard !Task.isCancelled else { return }

        let observationID = UUID()
        searchObservationID = observationID
        core.cancel(action: \.search)
        defer {
            if searchObservationID == observationID {
                searchObservationID = nil
                core.cancel(action: \.search)
            }
        }

        await DebouncedObservation.run(
            { [self] in
                SearchOptions(isPerfectMatch: isPerfectMatch, language: language)
            },
            for: .milliseconds(500)
        ) { [self] _ in
            guard searchObservationID == observationID else { return }

            core.cancel(action: \.search)
            search()
        }
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        try await refreshItem()
    }

    private func refreshItem() async throws {
        let entry = try await requireUserSession().getFullItem(item)
        try Task.checkCancellation()

        itemStorage = .init(value: entry)
    }

    @Function(\Action.Cases.search)
    private func _search() async throws {
        guard let itemID = item.id else {
            throw ErrorMessage(L10n.unknownError)
        }
        guard let language, language.isNotEmpty else {
            results = []
            return
        }

        let request = Paths.searchRemoteSubtitles(
            itemID: itemID,
            language: language,
            isPerfectMatch: isPerfectMatch
        )
        let results = try await send(request)
        try Task.checkCancellation()

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
                    _ = try await self.send(request)
                }
            }

            try await group.waitForAll()
        }

        try await refreshItem()

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
        _ = try await send(request)

        try await refreshItem()

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
                _ = try await send(request)
            } catch {
                throw ErrorMessage(L10n.failedDeletionAtIndexError(index, error))
            }
        }

        try await refreshItem()

        events.send(.deleted)
    }
}
