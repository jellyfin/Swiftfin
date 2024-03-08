//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Factory
import JellyfinAPI
import OrderedCollections

final class HomeViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action {
        case error(JellyfinAPIError)
        case refresh
    }

    // MARK: State

    enum State: Equatable {
        case content
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    var libraries: [LatestInLibraryViewModel] = []
    @Published
    var resumeItems: OrderedSet<BaseItemDto> = []

    @Published
    var state: State = .initial

    private(set) var nextUpViewModel: NextUpLibraryViewModel = .init()
    private(set) var recentlyAddedViewModel: RecentlyAddedLibraryViewModel = .init()

    private var refreshTask: AnyCancellable?

    func respond(to action: Action) -> State {
        switch action {
        case let .error(error):
            return .error(error)
        case .refresh:
            cancellables.removeAll()

            Task { [weak self] in
                guard let self else { return }
                do {

                    try await self.refresh()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.state = .content
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .store(in: &cancellables)

            return .refreshing
        }
    }

    private func refresh() async throws {

        Task {
            await nextUpViewModel.send(.refresh)
        }

        Task {
            await recentlyAddedViewModel.send(.refresh)
        }

        let resumeItems = try await getResumeItems()
        let libraries = try await getLibraries()

        for library in libraries {
            await library.send(.refresh)
        }

        await MainActor.run {
            self.resumeItems.elements = resumeItems
            self.libraries = libraries
        }
    }

    private func getResumeItems() async throws -> [BaseItemDto] {
        var parameters = Paths.GetResumeItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .episode]
        parameters.limit = 20

        let request = Paths.getResumeItems(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    private func getLibraries() async throws -> [LatestInLibraryViewModel] {

        let userViewsPath = Paths.getUserViews(userID: userSession.user.id)
        async let userViews = userSession.client.send(userViewsPath)

        async let excludedLibraryIDs = getExcludedLibraries()

        return try await (userViews.value.items ?? [])
            .intersection(["movies", "tvshows"], using: \.collectionType)
            .subtracting(excludedLibraryIDs, using: \.id)
            .map { LatestInLibraryViewModel(parent: $0) }
    }

    // TODO: eventually a more robust user/server information retrieval system
    //       will be in place. Replace with using the data from the remove user
    private func getExcludedLibraries() async throws -> [String] {
        let currentUserPath = Paths.getCurrentUser
        let response = try await userSession.client.send(currentUserPath)

        return response.value.configuration?.latestItemsExcludes ?? []
    }

    // TODO: fix
    func markItemUnplayed(_ item: BaseItemDto) {
//        guard resumeItems.contains(where: { $0.id == item.id! }) else { return }
//
//        Task {
//            let request = Paths.markUnplayedItem(
//                userID: userSession.user.id,
//                itemID: item.id!
//            )
//            let _ = try await userSession.client.send(request)
//
        ////            refreshResumeItems()
//
//            try await nextUpViewModel.refresh()
//            try await recentlyAddedViewModel.refresh()
//        }
    }

    // TODO: fix
    func markItemPlayed(_ item: BaseItemDto) {
//        guard resumeItems.contains(where: { $0.id == item.id! }) else { return }
//
//        Task {
//            let request = Paths.markPlayedItem(
//                userID: userSession.user.id,
//                itemID: item.id!
//            )
//            let _ = try await userSession.client.send(request)
//
        ////            refreshResumeItems()
//            try await nextUpViewModel.refresh()
//            try await recentlyAddedViewModel.refresh()
//        }
    }
}
