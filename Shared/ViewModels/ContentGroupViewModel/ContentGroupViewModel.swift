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
        case refreshPendingChanges

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.refreshing, then: .content)
                    .whenBackground(.refreshing)
            case .refreshPendingChanges:
                .background(.refreshing)
            }
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
    private var pendingRefreshes = ContentGroupRefreshQueue()
    private var scheduledRefresh: Task<Void, Never>?
    private var isRefreshInFlight = false
    private var isActive = false
    private var hasLoadedGroups = false

    var provider: Provider

    init(provider: Provider) {
        self.provider = provider
        super.init()

        provider.refreshRequests
            .sink { [weak self] request in
                self?.requestRefresh(request)
            }
            .store(in: &cancellables)
    }

    func setIsActive(_ isActive: Bool) {
        self.isActive = isActive
        if isActive {
            schedulePendingRefresh()
        } else {
            scheduledRefresh?.cancel()
            scheduledRefresh = nil
        }
    }

    private func requestRefresh(_ request: ContentGroupRefresh, groupID: String? = nil) {
        pendingRefreshes.insert(request, groupID: groupID)
        schedulePendingRefresh()
    }

    private func schedulePendingRefresh() {
        guard isActive, hasLoadedGroups, !isRefreshInFlight,
              !pendingRefreshes.isEmpty, scheduledRefresh == nil else { return }

        scheduledRefresh = Task { @MainActor [weak self] in
            // Coalesce changes from multiple groups and finish publishing their contents first.
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled, let self else { return }
            self.scheduledRefresh = nil
            await self.background.refreshPendingChanges()
        }
    }

    func refreshIfNeeded(
        sinceLastDisappear interval: TimeInterval,
        staleThreshold: TimeInterval = 60
    ) {
        if interval > staleThreshold {
            requestRefresh(.contents)
        } else {
            schedulePendingRefresh()
        }
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        guard !isRefreshInFlight else {
            requestRefresh(StateTask.isBackground ? .contents : .groups)
            return
        }

        pendingRefreshes.insert(StateTask.isBackground && hasLoadedGroups ? .contents : .groups)
        try await performRefresh(inBackground: StateTask.isBackground)
    }

    @Function(\Action.Cases.refreshPendingChanges)
    private func _refreshPendingChanges() async throws {
        guard isActive, hasLoadedGroups, !isRefreshInFlight, !pendingRefreshes.isEmpty else { return }
        try await performRefresh(inBackground: true)
    }

    private func performRefresh(inBackground: Bool) async throws {
        isRefreshInFlight = true
        scheduledRefresh?.cancel()
        scheduledRefresh = nil
        let pending = pendingRefreshes.take()
        defer { isRefreshInFlight = false }

        do {
            if pending.rebuildGroups {
                try await fullRefresh()
            } else {
                let groups = candidateGroups.filter { pending.refreshAll || pending.groupIDs.contains($0.id) }
                try await refreshViewModels(for: groups, inBackground: inBackground)
                try Task.checkCancellation()
                resolveGroups()
            }
        } catch {
            // Preserve failed work for the next appearance or explicit refresh, without a retry loop.
            pendingRefreshes.merge(pending)
            throw error
        }

        isRefreshInFlight = false
        schedulePendingRefresh()
    }

    private func getViewModel(for group: some ContentGroup) -> any WithRefresh {
        group.viewModel
    }

    private func resolveGroups() {
        let resolved = candidateGroups
            .filter(\._shouldBeResolved)
        if groups.map(\.id) != resolved.map(\.id) {
            groups = resolved
        }
    }

    private func observeGroups() {
        groupCancellables.removeAll()
        // Empty candidates can become visible after a store change, so observe them too.
        for group in candidateGroups {
            let id = group.id
            group.refreshRequests
                .sink { [weak self] request in
                    self?.requestRefresh(request, groupID: id)
                }
                .store(in: &groupCancellables)
        }
    }

    private func refreshViewModels(
        for groups: [any ContentGroup],
        inBackground: Bool
    ) async throws {
        let viewModels = groups.map { getViewModel(for: $0) }
            .uniqued { ObjectIdentifier($0 as AnyObject) }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for viewModel in viewModels {
                group.addTask {
                    if inBackground {
                        await viewModel.background.refresh()
                    } else {
                        await viewModel.refresh()
                    }
                }
            }

            try await group.waitForAll()
        }
    }

    private func fullRefresh() async throws {
        let newGroups = try await provider.makeGroups(environment: provider.environment)
        try Task.checkCancellation()

        candidateGroups = newGroups
        observeGroups()

        try await refreshViewModels(
            for: newGroups,
            // New view models must leave their initial state before replacing the visible groups.
            inBackground: false
        )

        try Task.checkCancellation()
        hasLoadedGroups = true
        // New groups may reuse IDs but own different view models.
        groups = candidateGroups.filter(\._shouldBeResolved)
    }
}
