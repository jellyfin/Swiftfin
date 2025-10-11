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

    @Published
    private(set) var sections: [(viewModel: any RefreshableViewModel, group: any _ContentGroup)] = []

    let provider: Provider

    // TODO: replace with views checking what notifications were
    //       posted since last disappear
    @Published
    var notificationsReceived: NotificationSet = .init()

    init(provider: Provider) {
        self.provider = provider

        super.init()

//        Notifications[.itemMetadataDidChange]
//            .publisher
//            .sink { _ in
//                // Necessary because when this notification is posted, even with asyncAfter,
//                // the view will cause layout issues since it will redraw while in landscape.
//                // TODO: look for better solution
//                DispatchQueue.main.async {
//                    self.notificationsReceived.insert(.itemMetadataDidChange)
//                }
//            }
//            .store(in: &cancellables)
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {

        func makePair(for group: any _ContentGroup) -> (viewModel: any RefreshableViewModel, group: any _ContentGroup) {
            func _makePair(for group: some _ContentGroup) -> (viewModel: any RefreshableViewModel, group: any _ContentGroup) {
                (viewModel: group.makeViewModel(), group: group)
            }
            return _makePair(for: group)
        }

        let newGroups = try await provider.makeGroups()
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
    let id: String = "home-\(UUID().uuidString)"
    let systemImage: String = "house.fill"

    func makeGroups() async throws -> [any _ContentGroup] {
        let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
        let userViewsPath = Paths.getUserViews(parameters: parameters)
        let userViews = try await userSession.client.send(userViewsPath)
        let excludedLibraryIDs = userSession.user.data.configuration?.latestItemsExcludes ?? []

        let latestInLibraries = (userViews.value.items ?? [])
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
            .map(PosterGroup.init)

        let newGroups: [any _ContentGroup] = [
            PosterGroup(library: ContinueWatchingLibrary()),
            PosterGroup(library: NextUpLibrary()),
        ]
            .appending(latestInLibraries)

        return newGroups
    }
}
