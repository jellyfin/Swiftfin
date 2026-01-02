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

final class DeleteItemViewModel: ViewModel, Stateful, Eventful {

    // MARK: - Events

    enum Event: Equatable {
        case deleted
        case error(ErrorMessage)
    }

    // MARK: - Action

    enum Action: Equatable {
        case delete
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case error(ErrorMessage)
    }

    @Published
    var state: State = .initial

    // MARK: - Published Item

    @Published
    var item: BaseItemDto?

    // MARK: Event Variables

    private var deleteTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .eraseToAnyPublisher()
        // Causes issues with the Deleted Event unless this is removed
        // .receive(on: RunLoop.main)
    }

    // MARK: - Initializer

    init(item: BaseItemDto) {
        self.item = item
        super.init()
    }

    // MARK: - Respond

    func respond(to action: Action) -> State {
        switch action {
        case .delete:
            deleteTask?.cancel()

            deleteTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await self.deleteItem()
                    await MainActor.run {
                        self.state = .initial
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
        }
    }

    // MARK: - Item Deletion Logic

    private func deleteItem() async throws {
        guard let item, let itemID = item.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        let request = Paths.deleteItem(itemID: itemID)
        _ = try await userSession.client.send(request)

        await MainActor.run {
            Notifications[.didDeleteItem].post(itemID)
            self.item = nil
        }
    }
}
