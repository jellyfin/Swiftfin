//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

// TODO: allow in-place changes in groups

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

    var provider: Provider

    init(provider: Provider) {
        self.provider = provider
        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        if StateTask.isBackground {
            try await backgroundRefresh()
        } else {
            try await fullRefresh()
        }
    }

    private func getViewModel(for group: some ContentGroup) -> any WithRefresh {
        group.viewModel
    }

    private func backgroundRefresh() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for viewModel in groups.map({ getViewModel(for: $0) }) {
                group.addTask {
                    await viewModel.background.refresh()
                }
            }

            try await group.waitForAll()
        }
    }

    private func fullRefresh() async throws {

        self.groups = []

        let newGroups = try await provider.makeGroups(environment: provider.environment)
        let viewModels = newGroups.map { getViewModel(for: $0) }
            .uniqued { ObjectIdentifier($0 as AnyObject) }

        try await withThrowingTaskGroup(of: Void.self) { group in

            for viewModel in viewModels {
                group.addTask {
                    await viewModel.refresh()
                }
            }

            try await group.waitForAll()
        }

        self.groups = newGroups
            .filter(\._shouldBeResolved)
    }
}
