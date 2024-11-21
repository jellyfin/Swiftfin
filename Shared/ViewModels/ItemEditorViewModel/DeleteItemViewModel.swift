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

class DeleteItemViewModel: ViewModel, Stateful, Eventful {

    // MARK: Events

    enum Event: Equatable {
        case error(JellyfinAPIError)
        case deleted
    }

    // MARK: Action

    enum Action: Equatable {
        case error(JellyfinAPIError)
        case delete
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    var item: BaseItemDto?

    @Published
    final var state: State = .initial

    private var deleteTask: AnyCancellable?

    // MARK: Event Variables

    private var eventSubject: PassthroughSubject<Event, Never> = .init()

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
            return .error(error)

        case .delete:
            deleteTask?.cancel()

            deleteTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await self.deleteItem()
                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.deleted)
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.state = .error(JellyfinAPIError(error.localizedDescription))
                        self.eventSubject.send(.error(JellyfinAPIError(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .refreshing
        }
    }

    // MARK: Metadata Refresh Logic

    private func deleteItem() async throws {
        guard let itemID = item?.id else {
            throw JellyfinAPIError(L10n.unknownError)
        }

        let request = Paths.deleteItem(itemID: itemID)
        _ = try await userSession.client.send(request)

        await MainActor.run {
            Notifications[.didDeleteItem].post(object: item)
            self.item = nil
        }
    }
}
