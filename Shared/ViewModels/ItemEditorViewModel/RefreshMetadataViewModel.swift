//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

class RefreshMetadataViewModel: ViewModel, Stateful, Eventful {

    // MARK: Events

    enum Event: Equatable {
        case error(JellyfinAPIError)
        case refreshTriggered
    }

    // MARK: Action

    enum Action: Equatable {
        case error(JellyfinAPIError)
        case refreshMetadata(
            metadataRefreshMode: MetadataRefreshMode,
            imageRefreshMode: MetadataRefreshMode,
            replaceMetadata: Bool,
            replaceImages: Bool
        )
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    // A spoof progress, since there isn't a
    // single item metadata refresh task
    @Published
    private(set) var progress: Double = 0.0

    @Published
    private var item: BaseItemDto
    @Published
    final var state: State = .initial

    private var itemTask: AnyCancellable?
    private var eventSubject = PassthroughSubject<Event, Never>()

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // MARK: Init

    init(item: BaseItemDto) {
        self.item = item
        super.init()
    }

    // MARK: Respond

    func respond(to action: Action) -> State {
        switch action {
        case let .error(error):
            eventSubject.send(.error(error))
            return .error(error)

        case let .refreshMetadata(metadataRefreshMode, imageRefreshMode, replaceMetadata, replaceImages):
            itemTask?.cancel()

            itemTask = Task { [weak self] in
                guard let self else { return }
                do {
                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.refreshTriggered)
                    }

                    try await self.refreshMetadata(
                        metadataRefreshMode: metadataRefreshMode,
                        imageRefreshMode: imageRefreshMode,
                        replaceMetadata: replaceMetadata,
                        replaceImages: replaceImages
                    )

                    await MainActor.run {
                        self.state = .refreshing
                        self.eventSubject.send(.refreshTriggered)
                    }

                    try await self.refreshItem()

                    await MainActor.run {
                        self.state = .content
                    }

                } catch {
                    guard !Task.isCancelled else { return }

                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }
            .asAnyCancellable()

            return .refreshing
        }
    }

    // MARK: Metadata Refresh Logic

    private func refreshMetadata(
        metadataRefreshMode: MetadataRefreshMode,
        imageRefreshMode: MetadataRefreshMode,
        replaceMetadata: Bool = false,
        replaceImages: Bool = false
    ) async throws {
        guard let itemId = item.id else { return }

        var parameters = Paths.RefreshItemParameters()
        parameters.metadataRefreshMode = metadataRefreshMode
        parameters.imageRefreshMode = imageRefreshMode
        parameters.isReplaceAllMetadata = replaceMetadata
        parameters.isReplaceAllImages = replaceImages

        let request = Paths.refreshItem(
            itemID: itemId,
            parameters: parameters
        )
        _ = try await userSession.client.send(request)
    }

    // MARK: Refresh Item After Request Queued

    private func refreshItem() async throws {
        guard let itemId = item.id else { return }

        let totalDuration: Double = 5.0
        let interval: Double = 0.05
        let steps = Int(totalDuration / interval)

        // Update progress every 0.05 seconds. Ticks up "1%" at a time.
        for i in 1 ... steps {
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

            let currentProgress = Double(i) / Double(steps)
            await MainActor.run {
                self.progress = currentProgress
            }
        }

        // After waiting for 5 seconds, fetch the updated item
        let request = Paths.getItem(userID: userSession.user.id, itemID: itemId)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.item = response.value
            self.progress = 0.0

            Notifications[.itemMetadataDidChange].post(object: item)
        }
    }
}
