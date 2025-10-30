//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@MainActor
@Stateful
final class ContentGroupViewModel<Provider: _ContentGroupProvider>: ViewModel {

    @CasePathable
    enum Action {
        case error
        case refresh

        var transition: Transition {
            switch self {
            case .error:
                .none
            case .refresh:
                .to(.refreshing, then: .content)
                    .whenBackground(.refreshing)
            }
        }
    }

    enum BackgroundState {
        case refreshing
    }

    enum State: Hashable {
        case content
        case error
        case initial
        case refreshing
    }

    var environment: Provider.Environment

    @Published
    private(set) var sections: [(viewModel: any _ContentGroupViewModel, group: any _ContentGroup)] = []

    var provider: Provider

    init(provider: Provider) {
        self.provider = provider
        self.environment = provider.environment
        super.init()
    }

    func _overrideProvider(_ provider: Provider) {
        self.provider = provider
        self.environment = provider.environment

        self.refresh()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {

        if sections.isNotEmpty {
            for s in sections {
                try? await s.viewModel.background.refresh()
            }

            return
        }

        func makePair(for group: any _ContentGroup) -> (viewModel: any _ContentGroupViewModel, group: any _ContentGroup) {
            func _makePair(for group: some _ContentGroup) -> (viewModel: any _ContentGroupViewModel, group: any _ContentGroup) {
                (viewModel: group.makeViewModel(), group: group)
            }
            return _makePair(for: group)
        }

        let newGroups = try await provider.makeGroups(environment: environment)
            .map(makePair)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for vm in newGroups.map(\.viewModel) {
                group.addTask {
                    try await vm.refresh()
                }
            }
            try await group.waitForAll()
        }

        self.sections = newGroups
    }
}

import Factory

struct DefaultContentGroupProvider: _ContentGroupProvider {

    @Injected(\.currentUserSession)
    var userSession: UserSession!

    let displayTitle: String = L10n.home
    let id: String = "default-content-group-provider"
    let systemImage: String = "house"

    @ContentGroupBuilder
    func makeGroups(environment: Void) async throws -> [any _ContentGroup] {
        let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
        let userViewsPath = Paths.getUserViews(parameters: parameters)
        let userViews = try await userSession.client.send(userViewsPath)
        let excludedLibraryIDs = userSession.user.data.configuration?.latestItemsExcludes ?? []

        PosterGroup(
            id: UUID().uuidString,
            library: ContinueWatchingLibrary(),
            posterDisplayType: .landscape,
            posterSize: .medium
        )

        PosterGroup(
            id: UUID().uuidString,
            library: NextUpLibrary()
        )

        PosterGroup(
            id: UUID().uuidString,
            library: PagingItemLibrary(
                parent: .init(
                    name: L10n.recentlyAdded
                ),
                filters: .init(
                    itemTypes: [.movie, .series],
                    sortBy: [.dateCreated],
                    sortOrder: [.descending]
                )
            )
        )

        (userViews.value.items ?? [])
            .intersection(
                [
                    .homevideos,
                    .movies,
                    .musicvideos,
                    .tvshows,
                ],
                using: \.collectionType
            )
            .subtracting(excludedLibraryIDs, using: \.id)
            .map(LatestInLibrary.init)
            .map { PosterGroup(id: UUID().uuidString, library: $0) }
    }
}
