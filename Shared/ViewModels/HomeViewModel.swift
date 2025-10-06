//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Factory
import Get
import JellyfinAPI
import OrderedCollections

@MainActor
@Stateful
final class HomeViewModel: ViewModel {

    @CasePathable
    enum Action {
        case error
        case setIsPlayed(played: Bool, item: BaseItemDto)
        case refresh

        var transition: Transition {
            switch self {
            case .error, .setIsPlayed:
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
    private(set) var sections: [any __PagingLibaryViewModel] = []

//    @Published
//    private(set) var libraries: [LatestInLibraryViewModel] = []
//    @Published
//    var resumeItems: OrderedSet<BaseItemDto> = []

    // TODO: replace with views checking what notifications were
    //       posted since last disappear
    @Published
    var notificationsReceived: NotificationSet = .init()

    private var backgroundRefreshTask: AnyCancellable?
    private var refreshTask: AnyCancellable?

//    var nextUpViewModel: NextUpLibraryViewModel = .init()
//    var recentlyAddedViewModel: RecentlyAddedLibraryViewModel = .init()

    override init() {
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

//    func respond(to action: Action) -> State {
//        switch action {
//        case .backgroundRefresh:
//
//            backgroundRefreshTask?.cancel()
//            backgroundStates.insert(.refresh)
//
//            backgroundRefreshTask = Task { [weak self] in
//                do {
//                    self?.nextUpViewModel.send(.refresh)
//                    self?.recentlyAddedViewModel.send(.refresh)
//
//                    let resumeItems = try await self?.getResumeItems() ?? []
//
//                    guard !Task.isCancelled else { return }
//
//                    await MainActor.run {
//                        guard let self else { return }
//                        self.resumeItems.elements = resumeItems
//                        self.backgroundStates.remove(.refresh)
//                    }
//                } catch is CancellationError {
//                    // cancelled
//                } catch {
//                    guard !Task.isCancelled else { return }
//
//                    await MainActor.run {
//                        guard let self else { return }
//                        self.backgroundStates.remove(.refresh)
//                        self.send(.error(.init(error.localizedDescription)))
//                    }
//                }
//            }
//            .asAnyCancellable()
//
//            return state
//        case let .error(error):
//            return .error(error)
//        case let .setIsPlayed(isPlayed, item): ()
//            Task {
//                try await setIsPlayed(isPlayed, for: item)
//
//                self.send(.backgroundRefresh)
//            }
//            .store(in: &cancellables)
//
//            return state
//        case .refresh:
//            backgroundRefreshTask?.cancel()
//            refreshTask?.cancel()
//
//            refreshTask = Task { [weak self] in
//                do {
//                    try await self?.refresh()
//
//                    guard !Task.isCancelled else { return }
//
//                    await MainActor.run {
//                        guard let self else { return }
//                        self.state = .content
//                    }
//                } catch is CancellationError {
//                    // cancelled
//                } catch {
//                    guard !Task.isCancelled else { return }
//
//                    await MainActor.run {
//                        guard let self else { return }
//                        self.send(.error(.init(error.localizedDescription)))
//                    }
//                }
//            }
//            .asAnyCancellable()
//
//            return .refreshing
//        }
//    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {

        func _library(for section: PosterSection) -> any __PagingLibaryViewModel {
            switch section {
            case .continueWatching:
                _PagingLibraryViewModel(library: ContinueWatchingLibrary())
            case let .latestInLibrary(id, name):
                _PagingLibraryViewModel(library: LatestInLibrary(library: .init(
                    id: id,
                    name: name,
                    type: .userView
                )))
            case .nextUp:
                _PagingLibraryViewModel(library: _PagingNextUpLibrary())
            case .recentlyAdded:
                _PagingLibraryViewModel(library: _PagingItemLibrary(
                    parent: BaseItemDto(name: L10n.recentlyAdded),
                    filters: .init(
                        parent: nil,
                        currentFilters: .init(
                            sortBy: [.dateCreated],
                            sortOrder: [.descending]
                        )
                    )
                ))
            }
        }

        let latestLibraries = try await getLibraries()
            .compactMap { item -> (id: String, title: String)? in
                guard let id = item.id else { return nil }
                return (id: id, title: item.displayTitle)
            }
            .map { PosterSection.latestInLibrary(id: $0.id, name: $0.title) }

        let sections: [any __PagingLibaryViewModel] = [
            PosterSection.continueWatching,
            .nextUp,
            .recentlyAdded,
        ]
            .appending(elementsOf: latestLibraries)
            .map { _library(for: $0) }

//        let sections: [any __PagingLibaryViewModel] = latestLibraries
//            .map(_library(for:))

        for library in sections {
            await library.refresh()
        }

        self.sections = sections
    }

    private func _setIsPlayed(_ isPlayed: Bool, _ item: BaseItemDto) async throws {
        let request: Request<UserItemDataDto>

        if isPlayed {
            request = Paths.markPlayedItem(
                itemID: item.id!,
                userID: userSession.user.id
            )
        } else {
            request = Paths.markUnplayedItem(
                itemID: item.id!,
                userID: userSession.user.id
            )
        }

        _ = try await userSession.client.send(request)
    }

    private func getLibraries() async throws -> [BaseItemDto] {

        let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
        let userViewsPath = Paths.getUserViews(parameters: parameters)
        async let userViews = userSession.client.send(userViewsPath)

        let excludedLibraryIDs = userSession.user.data.configuration?.latestItemsExcludes ?? []

        return try await (userViews.value.items ?? [])
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
    }
}
