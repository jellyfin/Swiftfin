//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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

        super.init()

        Notifications[.itemUserDataDidChange]
            .publisher
//            .filter { [weak self] userData in
//                guard let self else { return false }
//                return userData.itemId == self.item.id ||
//                    userData.itemId == self.playButtonItem?.id
//            }
            .sink { [weak self] userData in
                self?.updateItemUserData(userData)
            }
            .store(in: &cancellables)
    }

    private func updateItemUserData(_ userData: UserItemDataDto) {
        guard item.id == userData.itemID else { return }
        item = item.mutating(\.userData, with: userData)
    }

    private func notifyUserDataIfNeeded(for item: BaseItemDto) {
//        guard let itemId = item.id, let userData = item.userData else { return }
//
//        let shouldNotify = ItemUserDataCache.shared.updateIfNeeded(
//            itemId: itemId,
//            userData: userData
//        )
//
//        if shouldNotify {
//            Notifications[.itemUserDataDidChange].post(userData)
//        }
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let newItem = try await item.getFullItem(userSession: userSession)
        item = newItem
        notifyUserDataIfNeeded(for: newItem)

        Task {
            localTrailerViewModel.refresh()
        }

        if item.type == .series {
            playButtonItem = try await getNextUp(seriesID: item.id)
        } else {
            playButtonItem = newItem
        }

        if let playButtonItem {
            notifyUserDataIfNeeded(for: playButtonItem)
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
