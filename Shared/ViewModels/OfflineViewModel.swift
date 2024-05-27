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
import Get
import JellyfinAPI
import OrderedCollections

final class OfflineViewModel: ViewModel, Stateful {

    @Injected(Container.downloadManager)
    private var downloadManager

    // MARK: Action

    enum Action: Equatable {
        case backgroundRefresh
        case error(JellyfinAPIError)
        case setIsPlayed(Bool, DownloadEntity)
        case removeDownload(DownloadEntity)
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
    var resumeItems: OrderedSet<DownloadEntity> = []
    @Published
    private(set) var libraries: [DownloadLibraryViewModel] = []

    @Published
    var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    var lastAction: Action? = nil
    @Published
    var state: State = .initial

    // TODO: replace with views checking what notifications were
    //       posted since last disappear
    @Published
    var notificationsReceived: Set<Notifications.Key> = []

    private var backgroundRefreshTask: AnyCancellable?
    private var refreshTask: AnyCancellable?

    var nextUpViewModel: OfflineNextUpLibraryViewModel = .init()

    override init() {
        super.init()

        Notifications[.itemMetadataDidChange].publisher
            .sink { _ in
                // Necessary because when this notification is posted, even with asyncAfter,
                // the view will cause layout issues since it will redraw while in landscape.
                // TODO: look for better solution
                DispatchQueue.main.async {
                    self.notificationsReceived.insert(Notifications.Key.itemMetadataDidChange)
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
                self?.nextUpViewModel.send(.refresh)

                let resumeItems = self?.getResumeItems() ?? []

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard let self else { return }
                    self.resumeItems.elements = resumeItems
                    self.backgroundStates.remove(.refresh)
                }
            }
            .asAnyCancellable()

            return state
        case let .error(error):
            return .error(error)
        case let .removeDownload(task):
            Task {
                downloadManager.remove(task: task)
                self.send(.backgroundRefresh)
            }
            return state
        case let .setIsPlayed(isPlayed, item): ()
            Task {
                setIsPlayed(isPlayed, for: item)

                self.send(.backgroundRefresh)
            }
            .store(in: &cancellables)

            return state
        case .refresh:
            backgroundRefreshTask?.cancel()
            refreshTask?.cancel()

            refreshTask = Task { [weak self] in
                do {
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

            return .refreshing
        }
    }

    private func refresh() async throws {

        await nextUpViewModel.send(.refresh)

        await MainActor.run {
            self.resumeItems.elements = []
        }

        let resumeItems = getResumeItems()
        let libraries = getLibraries()

        for library in libraries {
            await library.send(.refresh)
        }

        await MainActor.run {
            self.resumeItems.elements = resumeItems
            self.libraries = libraries
        }
    }

    func getDownloadForItem(item: BaseItemDto) -> DownloadEntity? {
        // TODO: handle errors properly
        downloadManager.downloads.first { download in download.item.id == item.id }
    }

    private func getResumeItems() -> [DownloadEntity] {
        // TODO: settings for resume percentage
        downloadManager.downloads.filter { item in item.item.userData?.playedPercentage ?? 0 > 5 }
    }

    private func getLibraries() -> [DownloadLibraryViewModel] {
        let series = downloadManager.downloads
            .filter { item in item.item.seriesID != nil }
            .map { item in item.seriesItem }.uniqued()
            .compactMap { $0 }

        return [
            DownloadLibraryViewModel(
                series,
                parent: TitledLibraryParent(
                    displayTitle: "Shows",
                    id: "shows"
                )
            ),
            DownloadLibraryViewModel(
                downloadManager.downloads.filter { item in item.item.seriesID == nil }.map { item in item.item },
                parent: TitledLibraryParent(
                    displayTitle: "Movies",
                    id: "movies"
                )
            ),
        ]
    }

    private func getExcludedLibraries() async throws -> [String] {
        []
    }

    private func setIsPlayed(_ isPlayed: Bool, for item: DownloadEntity) {
        item.savePlaybackInfo(positionTicks: 0)
        item.setIsPlayed(played: isPlayed)
    }
}
