//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

@Stateful
class _ItemViewModel: ViewModel, WithRefresh {

    @CasePathable
    enum Action {
        case refresh

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.refreshing, then: .content)
            }
        }
    }

    enum State: Hashable {
        case content
        case error
        case initial
        case refreshing
    }

    @Published
    var item: BaseItemDto = .init()
    @Published
    private(set) var playButtonItem: BaseItemDto? {
        willSet {
            selectedMediaSource = newValue?.mediaSources?.first
        }
    }

    @Published
    var selectedMediaSource: MediaSourceInfo?

    @ObservedPublisher
    var localTrailers: [BaseItemDto]

    private var localTrailerViewModel: PagingLibraryViewModel<LocalTrailerLibrary>

    init(id: String) {
        self.item = .init(id: id)
        self.localTrailerViewModel = .init(library: .init(parentID: id))

        self._localTrailers = .init(
            wrappedValue: [],
            observing: localTrailerViewModel.$elements.map(\.elements)
        )
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let newItem = try await item.getFullItem(userSession: userSession)
        item = newItem

        Task {
            localTrailerViewModel.refresh()
        }

        if item.type == .series {
            playButtonItem = try await getNextUp(seriesID: item.id)
        } else {
            playButtonItem = newItem
        }
    }

    private func getNextUp(seriesID: String?) async throws -> BaseItemDto? {
        var parameters = Paths.GetNextUpParameters()
        parameters.enableUserData = true
        parameters.fields = [.mediaSources]
        parameters.seriesID = seriesID
        parameters.userID = userSession.user.id

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await userSession.client.send(request)

        guard let item = response.value.items?.first, !item.isMissing else {
            return nil
        }

        return item
    }
}

import Combine

/// Observable object property wrapper that allows observing
/// another `Publisher`.
@propertyWrapper
final class ObservedPublisher<Value>: ObservableObject {

    @Published
    private(set) var wrappedValue: Value

    var projectedValue: AnyPublisher<Value, Never> {
        $wrappedValue
            .eraseToAnyPublisher()
    }

    private var cancellables = Set<AnyCancellable>()

    init<P: Publisher>(
        wrappedValue: Value,
        observing publisher: P
    ) where P.Output == Value, P.Failure == Never {
        self.wrappedValue = wrappedValue

        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.wrappedValue = newValue
            }
            .store(in: &cancellables)
    }

    static subscript<T: ObservableObject>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: KeyPath<T, Value>,
        storage storageKeyPath: KeyPath<T, ObservedPublisher<Value>>
    ) -> Value where T.ObjectWillChangePublisher == ObservableObjectPublisher {
        let wrapper = instance[keyPath: storageKeyPath]

        wrapper.objectWillChange
            .sink { [weak instance] _ in
                instance?.objectWillChange.send()
            }
            .store(in: &wrapper.cancellables)

        return wrapper.wrappedValue
    }
}
