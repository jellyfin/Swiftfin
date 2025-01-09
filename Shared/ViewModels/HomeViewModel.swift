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

/// 100ms
let childPollDuration: UInt64 = 100_000_000

final class HomeViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case backgroundRefresh
        case error(JellyfinAPIError)
        case setIsPlayed(Bool, BaseItemDto)
        case refresh
    }

    // MARK: BackgroundState

    enum BackgroundState: Hashable {
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    private(set) var libraries: [LatestInLibraryViewModel] = []
    @Published
    var resumeItems: OrderedSet<BaseItemDto> = []

    @Published
    var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    var lastAction: Action? = nil
    @Published
    var state: State = .initial

    // TODO: replace with views checking what notifications were
    //       posted since last disappear
    @Published
    var notificationsReceived: NotificationSet = .init()

    private var backgroundRefreshTask: AnyCancellable?
    private var refreshTask: AnyCancellable?
    private var childRefreshTasks: [Task<Void, Error>] = []

    @Published
    var nextUpViewModel: NextUpLibraryViewModel = .init()
    @Published
    var recentlyAddedViewModel: RecentlyAddedLibraryViewModel = .init()

    override init() {
        super.init()

        Notifications[.itemMetadataDidChange]
            .publisher
            .sink { _ in
                // Necessary because when this notification is posted, even with asyncAfter,
                // the view will cause layout issues since it will redraw while in landscape.
                // TODO: look for better solution
                DispatchQueue.main.async {
                    self.notificationsReceived.insert(.itemMetadataDidChange)
                }
            }
            .store(in: &cancellables)
    }

    func respond(to action: Action) -> State {
        switch action {
        case .backgroundRefresh:
            backgroundRefreshTask?.cancel()
            backgroundStates.append(.refresh)

            backgroundRefreshTask = Task { [weak self] in
                do {
                    let nextUpTask = Task {
                        self?.nextUpViewModel.send(.refresh)
                        while self?.nextUpViewModel.state == .refreshing {
                            try await Task.sleep(nanoseconds: childPollDuration)
                        }
                    }

                    let recentlyAddedTask = Task {
                        self?.recentlyAddedViewModel.send(.refresh)
                        while self?.recentlyAddedViewModel.state == .refreshing {
                            try await Task.sleep(nanoseconds: childPollDuration)
                        }
                    }

                    try await nextUpTask.value
                    try await recentlyAddedTask.value

                    let resumeItems = try await self?.getResumeItems() ?? []

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        guard let self else { return }
                        self.resumeItems.elements = resumeItems
                        self.backgroundStates.remove(.refresh)
                    }
                } catch is CancellationError {
                    // cancelled
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        guard let self else { return }
                        self.backgroundStates.remove(.refresh)
                        self.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .error(error):
            return .error(error)

        case let .setIsPlayed(isPlayed, item):
            Task {
                try await setIsPlayed(isPlayed, for: item)
                self.send(.backgroundRefresh)
            }
            .store(in: &cancellables)

            return state

        case .refresh:
            backgroundRefreshTask?.cancel()
            refreshTask?.cancel()

            childRefreshTasks.forEach { $0.cancel() }
            childRefreshTasks.removeAll()

            refreshTask = Task { [weak self] in
                do {
                    await MainActor.run {
                        guard let self else { return }
                        self.state = .refreshing
                    }

                    let nextUpTask = Task {
                        self?.nextUpViewModel.send(.refresh)
                        while self?.nextUpViewModel.state == .refreshing {
                            try await Task.sleep(nanoseconds: childPollDuration)
                        }
                    }

                    let recentlyAddedTask = Task {
                        self?.recentlyAddedViewModel.send(.refresh)
                        while self?.recentlyAddedViewModel.state == .refreshing {
                            try await Task.sleep(nanoseconds: childPollDuration)
                        }
                    }

                    self?.childRefreshTasks = [nextUpTask, recentlyAddedTask]

                    try await nextUpTask.value
                    try await recentlyAddedTask.value

                    try await self?.refresh()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        guard let self else { return }
                        self.state = .content
                    }
                } catch is CancellationError {
                    // cancelled
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        guard let self else { return }
                        self.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    private func refresh() async throws {
        let resumeItems = try await getResumeItems()
        let libraries = try await getLibraries()

        let libraryTasks = libraries.map { library in
            Task {
                await library.send(.refresh)
                while library.state == .refreshing {
                    try await Task.sleep(nanoseconds: childPollDuration)
                }
            }
        }

        /// Wait for all library refreshes to complete before state change
        try await withThrowingTaskGroup(of: Void.self) { group in
            for task in libraryTasks {
                group.addTask {
                    try await task.value
                }
            }
            try await group.waitForAll()
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

    // TODO: use the more updated server/user data when implemented
    private func getExcludedLibraries() async throws -> [String] {
        let currentUserPath = Paths.getCurrentUser
        let response = try await userSession.client.send(currentUserPath)

        return response.value.configuration?.latestItemsExcludes ?? []
    }

    private func setIsPlayed(_ isPlayed: Bool, for item: BaseItemDto) async throws {
        let request: Request<UserItemDataDto>

        if isPlayed {
            request = Paths.markPlayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
        } else {
            request = Paths.markUnplayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
        }

        let _ = try await userSession.client.send(request)
    }
}
