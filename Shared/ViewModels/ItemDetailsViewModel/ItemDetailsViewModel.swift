//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

//
// Swiftfin is subject to the terms of the Mozilla Public License, v2.0.
// If a copy of the MPL was not distributed with this file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

class ItemDetailsViewModel<ItemType: Equatable>: ViewModel, Stateful, Eventful {

    // MARK: - Events

    enum Event: Equatable {
        case updated
        case error(JellyfinAPIError)
    }

    // MARK: - Actions

    enum Action: Equatable {
        case add([ItemType])
        case remove([ItemType])
        case update(BaseItemDto)
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case error(JellyfinAPIError)
        case updating
        case refreshing
    }

    @Published
    var item: BaseItemDto

    @Published
    var state: State = .initial

    private var updateTask: AnyCancellable?
    private let eventSubject = PassthroughSubject<Event, Never>()

    var events: AnyPublisher<Event, Never> {
        eventSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    // MARK: - Init

    init(item: BaseItemDto) {
        self.item = item
        super.init()
    }

    // MARK: - Respond to Actions

    func respond(to action: Action) -> State {
        switch action {
        case let .add(items):
            return updateStateAndPerform(.updated) {
                try await self.addItems(items)
            }
        case let .remove(items):
            return updateStateAndPerform(.updated) {
                try await self.removeItems(items)
            }
        case let .update(item):
            return updateStateAndPerform(.updated) {
                _ = self.updateItem(item)
            }
        }
    }

    // MARK: - Update State and Perform Operation

    private func updateStateAndPerform(_ event: Event, operation: @escaping () async throws -> Void) -> State {
        cancelCurrentTask()

        updateTask = Task { [weak self] in
            guard let self = self else { return }
            await self.setState(.updating)

            do {
                try await operation()
                await self.completeWithSuccess(event)
            } catch {
                await self.handleTaskError(error)
            }
        }.asAnyCancellable()

        return .refreshing
    }

    // MARK: - Cancel Current Task

    private func cancelCurrentTask() {
        updateTask?.cancel()
    }

    // MARK: - Complete with Success

    private func completeWithSuccess(_ event: Event) async {
        await setState(.initial)
        eventSubject.send(event)
    }

    // MARK: - Handle Task Error

    private func handleTaskError(_ error: Error) async {
        guard !Task.isCancelled else { return }
        let apiError = JellyfinAPIError(error.localizedDescription)
        await setState(.error(apiError))
        eventSubject.send(.error(apiError))
    }

    // MARK: - Update Item on Server

    func updateItem(_ newItem: BaseItemDto, refresh: Bool = false) -> State {
        updateStateAndPerform(.updated) {
            try await self.saveUpdatedItem(newItem)
            if refresh {
                try await self.refreshItemFromServer()
            } else {
                await self.updateItemLocally(newItem)
            }
            Notifications[.itemMetadataDidChange].post(object: newItem)
        }
    }

    // MARK: - Save Updated Item to Server

    private func saveUpdatedItem(_ newItem: BaseItemDto) async throws {
        guard let itemId = item.id else { return }
        let request = Paths.updateItem(itemID: itemId, newItem)
        _ = try await userSession.client.send(request)
    }

    // MARK: - Refresh Item from Server

    private func refreshItemFromServer() async throws {
        guard let itemId = item.id else { return }
        let request = Paths.getItem(userID: userSession.user.id, itemID: itemId)
        let response = try await userSession.client.send(request)
        await updateItemLocally(response.value)
    }

    // MARK: - Update Item Locally

    private func updateItemLocally(_ newItem: BaseItemDto) async {
        await MainActor.run {
            self.item = newItem
        }
    }

    // MARK: - Set State

    private func setState(_ newState: State) async {
        await MainActor.run {
            self.state = newState
        }
    }

    // MARK: - Add Items (To be overridden)

    func addItems(_ items: [ItemType]) async throws {
        fatalError("This method should be overridden in subclasses")
    }

    // MARK: - Remove Items (To be overridden)

    func removeItems(_ items: [ItemType]) async throws {
        fatalError("This method should be overridden in subclasses")
    }
}
