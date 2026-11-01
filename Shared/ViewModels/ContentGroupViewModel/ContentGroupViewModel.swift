//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation

@MainActor
@Stateful
final class ContentGroupViewModel<Provider: ContentGroupProvider>: ViewModel {

    @CasePathable
    enum Action {

        case refresh

        var transition: Transition {
            .to(.refreshing, then: .content)
                .whenBackground(.refreshing)
        }
    }

    enum BackgroundState {

        case refreshing
    }

    enum State {

        case content
        case error
        case initial
        case refreshing
    }

    @Published
    private(set) var groups: [any ContentGroup] = []

    private var candidateGroups: [any ContentGroup] = []
    private var groupCancellables = Set<AnyCancellable>()
    private var needsGroupRebuild = true
    private var isRefreshingGroups = false
    private let refreshSource = UUID()

    var provider: Provider

    init(provider: Provider) {
        self.provider = provider
        super.init()

        provider.refreshRequests
            .filter { [refreshSource] in $0.source != refreshSource }
            .handleEvents(receiveOutput: { [weak self] _ in self?.needsGroupRebuild = true })
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, self.state == .content else { return }

                self.refreshIfPendingChanges()
            }
            .store(in: &cancellables)
    }

    func refreshIfNeeded(
        sinceLastDisappear interval: TimeInterval,
        staleThreshold: TimeInterval = 60
    ) {
        guard interval > staleThreshold || needsGroupRebuild else { return }

        background.refresh()
    }

    func refreshIfPendingChanges() {
        guard needsGroupRebuild, !isRefreshingGroups else { return }

        background.refresh()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        if !StateTask.isBackground {
            needsGroupRebuild = true
        }

        guard !isRefreshingGroups else { return }

        let rebuildGroups = needsGroupRebuild
        needsGroupRebuild = false

        do {
            isRefreshingGroups = true
            defer { isRefreshingGroups = false }

            try await ContentGroupRefreshRequest.$currentSource.withValue(refreshSource) {
                if rebuildGroups {
                    try await fullRefresh()
                } else {
                    await refreshViewModels(in: candidateGroups, inBackground: true)
                    try Task.checkCancellation()
                    resolveGroups()
                }
            }
        } catch {
            needsGroupRebuild = needsGroupRebuild || rebuildGroups
            throw error
        }

        refreshIfPendingChanges()
    }

    private func resolveGroups() {
        let resolved = candidateGroups.filter(\._shouldBeResolved)

        if groups.map(\.id) != resolved.map(\.id) {
            groups = resolved
        }
    }

    private func uniqueViewModels(in groups: [any ContentGroup]) -> [any WithRefresh] {
        var seen = Set<ObjectIdentifier>()
        return groups.map { $0.viewModel as any WithRefresh }
            .filter { seen.insert(ObjectIdentifier($0 as AnyObject)).inserted }
    }

    private func observeGroups() {
        groupCancellables.removeAll()

        for case let viewModel as ViewModel in uniqueViewModels(in: candidateGroups) {
            viewModel.objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.resolveGroups()
                }
                .store(in: &groupCancellables)
        }
    }

    private func refreshViewModels(in groups: [any ContentGroup], inBackground: Bool) async {
        await withTaskGroup(of: Void.self) { group in
            for viewModel in uniqueViewModels(in: groups) {
                group.addTask {
                    if inBackground {
                        await viewModel.background.refresh()
                    } else {
                        await viewModel.refresh()
                    }
                }
            }
        }
    }

    private func fullRefresh() async throws {
        let newGroups = try await provider.makeGroups(environment: provider.environment)
        try Task.checkCancellation()

        await refreshViewModels(in: newGroups, inBackground: false)
        try Task.checkCancellation()

        candidateGroups = newGroups
        observeGroups()

        // New groups may reuse IDs but own different view models
        groups = candidateGroups.filter(\._shouldBeResolved)
    }
}
