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
    private var scheduledRebuild: Task<Void, Never>?
    private var needsGroupRebuild = true
    private var hasLoadedGroups = false

    var provider: Provider

    init(provider: Provider) {
        self.provider = provider
        super.init()

        provider.refreshRequests
            .sink { [weak self] in
                self?.needsGroupRebuild = true
                self?.scheduleGroupRebuild()
            }
            .store(in: &cancellables)
    }

    deinit {
        scheduledRebuild?.cancel()
    }

    private func scheduleGroupRebuild() {
        guard state != .refreshing, hasLoadedGroups, needsGroupRebuild, scheduledRebuild == nil else { return }

        scheduledRebuild = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled, let self else { return }

            self.scheduledRebuild = nil
            await self.background.refresh()
        }
    }

    func refreshIfNeeded(
        sinceLastDisappear interval: TimeInterval,
        staleThreshold: TimeInterval = 60
    ) {
        guard interval > staleThreshold || needsGroupRebuild else { return }

        background.refresh()
    }

    func refreshIfPendingChanges() {
        guard needsGroupRebuild else { return }

        background.refresh()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        if !StateTask.isBackground {
            needsGroupRebuild = true
        }

        scheduledRebuild?.cancel()
        scheduledRebuild = nil

        let rebuildGroups = needsGroupRebuild
        needsGroupRebuild = false

        do {
            if rebuildGroups {
                try await fullRefresh()
            } else {
                await refreshViewModels(in: candidateGroups, inBackground: true)
                try Task.checkCancellation()
                resolveGroups()
            }
        } catch {
            needsGroupRebuild = needsGroupRebuild || rebuildGroups
            throw error
        }

        scheduleGroupRebuild()
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
        hasLoadedGroups = true

        // New groups may reuse IDs but own different view models
        groups = candidateGroups.filter(\._shouldBeResolved)
    }
}
