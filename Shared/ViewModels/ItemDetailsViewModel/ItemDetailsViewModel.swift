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

class ItemDetailsViewModel: ViewModel, Stateful, Eventful {

    // MARK: - Events

    enum Event: Equatable {
        case added
        case removed
        case updated
        case error(JellyfinAPIError)
    }

    // MARK: - Actions

    enum Action: Equatable {
        case error(JellyfinAPIError)
        case updateItem(BaseItemDto)
        case addPeople([BaseItemPerson])
        case removePeople([BaseItemPerson])
        case addStudios([NameGuidPair])
        case removeStudios([NameGuidPair])
        case addGenres([String])
        case removeGenres([String])
        case addTags([String])
        case removeTags([String])
    }

    // MARK: - State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    var item: BaseItemDto
    @Published
    final var state: State = .initial

    private var updateTask: AnyCancellable?

    // MARK: - Event Variables

    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Init

    init(item: BaseItemDto) {
        self.item = item
        super.init()
    }

    // MARK: - Respond to Actions

    func respond(to action: Action) -> State {
        switch action {
        case let .error(error):
            eventSubject.send(.error(error))
            return .error(error)

        case let .updateItem(item):
            return performUpdate(.updated) { [weak self] in
                try await self?.updateItem(item)
            }

        case let .addPeople(newPeople):
            return performUpdate(.added) { [weak self] in
                try await self?.addPeople(newPeople)
            }

        case let .removePeople(peopleToRemove):
            return performUpdate(.removed) { [weak self] in
                try await self?.removePeople(peopleToRemove)
            }

        case let .addStudios(newStudios):
            return performUpdate(.added) { [weak self] in
                try await self?.addStudios(newStudios)
            }

        case let .removeStudios(studiosToRemove):
            return performUpdate(.removed) { [weak self] in
                try await self?.removeStudios(studiosToRemove)
            }

        case let .addGenres(newGenres):
            return performUpdate(.added) { [weak self] in
                try await self?.addGenres(newGenres)
            }

        case let .removeGenres(genresToRemove):
            return performUpdate(.removed) { [weak self] in
                try await self?.removeGenres(genresToRemove)
            }

        case let .addTags(newTags):
            return performUpdate(.added) { [weak self] in
                try await self?.addTags(newTags)
            }

        case let .removeTags(tagsToRemove):
            return performUpdate(.removed) { [weak self] in
                try await self?.removeTags(tagsToRemove)
            }
        }
    }

    // MARK: - Perform Update

    private func performUpdate(_ event: Event, _ operation: @escaping () async throws -> Void) -> State {
        updateTask?.cancel()
        updateTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await operation()
                await MainActor.run {
                    self.state = .content
                    self.eventSubject.send(event)
                }
            } catch {
                guard !Task.isCancelled else { return }
                let apiError = JellyfinAPIError(error.localizedDescription)
                await MainActor.run {
                    self.state = .error(apiError)
                    self.eventSubject.send(.error(apiError))
                }
            }
        }.asAnyCancellable()
        return .refreshing
    }

    // MARK: - Update Item

    private func updateItem(_ newItem: BaseItemDto) async throws {
        guard let itemId = item.id else { return }

        let refreshRequest = Paths.updateItem(itemID: itemId, newItem)
        _ = try await userSession.client.send(refreshRequest)

        // TODO: Figure out why I need to call this from the Server instead of being able to just set item = newItem.
        // This only impacts .studios & .people, I think because those records are kind of 'assembled' on the server because we only provide name.
        // Then, the Server turns that into a complete Person / Studio record.
        try await refreshItem()
    }

    // MARK: - Add People

    private func addPeople(_ newPeople: [BaseItemPerson]) async throws {
        var updatedItem = item
        updatedItem.people?.append(contentsOf: newPeople)
        try await updateItem(updatedItem)
    }

    // MARK: - Remove People

    private func removePeople(_ peopleToRemove: [BaseItemPerson]) async throws {
        var updatedItem = item
        updatedItem.people?.removeAll { peopleToRemove.contains($0) }
        try await updateItem(updatedItem)
    }

    // MARK: - Add Studios

    private func addStudios(_ newStudios: [NameGuidPair]) async throws {
        var updatedItem = item
        updatedItem.studios?.append(contentsOf: newStudios)
        try await updateItem(updatedItem)
    }

    // MARK: - Remove Studios

    private func removeStudios(_ studiosToRemove: [NameGuidPair]) async throws {
        var updatedItem = item
        updatedItem.studios?.removeAll { studiosToRemove.contains($0) }
        try await updateItem(updatedItem)
    }

    // MARK: - Add Genres

    private func addGenres(_ newGenres: [String]) async throws {
        var updatedItem = item
        if updatedItem.genres == nil {
            updatedItem.genres = []
        }
        updatedItem.genres?.append(contentsOf: newGenres)
        try await updateItem(updatedItem)
    }

    // MARK: - Remove Genres

    private func removeGenres(_ genresToRemove: [String]) async throws {
        var updatedItem = item
        updatedItem.genres?.removeAll { genresToRemove.contains($0) }
        try await updateItem(updatedItem)
    }

    // MARK: - Add Tags

    private func addTags(_ newTags: [String]) async throws {
        var updatedItem = item
        if updatedItem.tags == nil {
            updatedItem.tags = []
        }
        updatedItem.tags?.append(contentsOf: newTags)
        try await updateItem(updatedItem)
    }

    // MARK: - Remove Tags

    private func removeTags(_ tagsToRemove: [String]) async throws {
        var updatedItem = item
        updatedItem.tags?.removeAll { tagsToRemove.contains($0) }
        try await updateItem(updatedItem)
    }

    // MARK: - Refresh Item

    private func refreshItem() async throws {
        guard let itemId = item.id else { return }

        let request = Paths.getItem(userID: userSession.user.id, itemID: itemId)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.item = response.value
            Notifications[.itemMetadataDidChange].post(object: item)
        }
    }
}
