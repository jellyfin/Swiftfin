//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

class CollectionEditorViewModel: ViewModel, Stateful, Eventful {

    // MARK: Event

    enum Event: Equatable {
        case updated
        case error(JellyfinAPIError)
    }

    // MARK: Action

    enum Action: Equatable {
        case refresh
        case createCollection(_ name: String, items: [String] = [], search: Bool = false)
        case addItem(collectionID: String, items: [String])
        case removeItem(collectionID: String, items: [String])
        case error(JellyfinAPIError)
    }

    // MARK: BackgroundState

    enum BackgroundState: Hashable {
        case update
    }

    // MARK: State

    enum State: Hashable {
        case initial
        case refreshing
        case content
        case error(JellyfinAPIError)
    }

    @Published
    var state: State = .initial
    @Published
    var backgroundStates: Set<BackgroundState> = []
    @Published
    var collections: [BaseItemDto] = []

    private let eventSubject = PassthroughSubject<Event, Never>()

    var events: AnyPublisher<Event, Never> {
        eventSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    private var refreshTask: AnyCancellable?
    private var createCollectionTask: AnyCancellable?
    private var addToCollectionTask: AnyCancellable?
    private var removeFromCollectionTask: AnyCancellable?

    // MARK: Respond

    func respond(to action: Action) -> State {
        switch action {
        case .refresh:

            refreshTask?.cancel()

            refreshTask = Task { [weak self] in
                guard let self else { return }
                do {
                    let collections = try await getCollections()

                    await MainActor.run {
                        self.collections = collections
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .refreshing

        case let .createCollection(name, items, search):

            createCollectionTask?.cancel()

            backgroundStates.insert(.update)

            createCollectionTask = Task { [weak self] in
                guard let self else { return }
                do {
                    try await createCollection(name: name, items: items, search: search)

                    await MainActor.run {
                        self.backgroundStates.remove(.update)
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    await MainActor.run {
                        self.backgroundStates.remove(.update)
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .addItem(collectionID, items):

            addToCollectionTask?.cancel()

            backgroundStates.insert(.update)

            addToCollectionTask = Task { [weak self] in
                guard let self else { return }
                do {
                    try await addToCollection(collectionID: collectionID, items: items)

                    await MainActor.run {
                        self.backgroundStates.remove(.update)
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    await MainActor.run {
                        self.backgroundStates.remove(.update)
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .removeItem(collectionID, items):

            removeFromCollectionTask?.cancel()

            backgroundStates.insert(.update)

            removeFromCollectionTask = Task { [weak self] in
                guard let self else { return }
                do {
                    try await removeFromCollection(collectionID: collectionID, items: items)

                    await MainActor.run {
                        self.backgroundStates.remove(.update)
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    await MainActor.run {
                        self.backgroundStates.remove(.update)
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .error(error):
            return .error(error)
        }
    }

    // MARK: Get All Collections

    private func getCollections() async throws -> [BaseItemDto] {
        let parameters = Paths.GetItemsByUserIDParameters(
            isRecursive: true,
            fields: .MinimumFields,
            includeItemTypes: [.boxSet],
            sortBy: [ItemSortBy.name.rawValue]
        )
        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    // MARK: Create Collection

    private func createCollection(name: String, items: [String] = [], search: Bool = false) async throws {
        let parameters = Paths.CreateCollectionParameters(name: name, ids: items, isLocked: !search)
        let request = Paths.createCollection(parameters: parameters)
        _ = try await userSession.client.send(request)
    }

    // MARK: Add To Collection

    private func addToCollection(collectionID: String, items: [String] = []) async throws {
        let request = Paths.addToCollection(collectionID: collectionID, ids: items)
        _ = try await userSession.client.send(request)
        Notifications[.itemShouldRefreshMetadata].post(collectionID)
    }

    // MARK: Remove From Collection

    private func removeFromCollection(collectionID: String, items: [String] = []) async throws {
        let request = Paths.removeFromCollection(collectionID: collectionID, ids: items)
        _ = try await userSession.client.send(request)
        Notifications[.itemShouldRefreshMetadata].post(collectionID)
    }
}
