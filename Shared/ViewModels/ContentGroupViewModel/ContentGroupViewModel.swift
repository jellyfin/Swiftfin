//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// TODO: allow in-place changes in groups

@MainActor
@Stateful
final class ContentGroupViewModel<Provider: _ContentGroupProvider>: ViewModel {

    @CasePathable
    enum Action {
        case backgroundRefresh
        case error
        case refresh

        var transition: Transition {
            switch self {
            case .backgroundRefresh:
                .background(.refreshing)
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

    enum State {
        case content
        case error
        case initial
        case refreshing
    }

    @Published
    private(set) var groups: [any _ContentGroup] = []

    var provider: Provider

    init(provider: Provider) {
        self.provider = provider
        super.init()
    }

//    @Function(\Action.Cases.refresh)
//    private func _backgroundRefresh() async throws {
//        for section in sections {
//            try await section.viewModel.background.refresh()
//        }
//    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {

//        if sections.isNotEmpty {
//            for section in sections {
//                await section.viewModel.background.refresh()
//            }
//
//            return
//        }

        func getViewModel<T: _ContentGroup>(for group: T) -> any WithRefresh {
            group.viewModel
        }

        let newGroups = try await provider.makeGroups(environment: provider.environment)
        let viewModels = newGroups.map { getViewModel(for: $0) }
            .uniqued { ObjectIdentifier($0 as AnyObject) }

        self.groups = newGroups

        try await withThrowingTaskGroup(of: Void.self) { group in

            for viewModel in viewModels {
                group.addTask {
                    await viewModel.refresh()
                }
            }

            try await group.waitForAll()
        }
    }
}
