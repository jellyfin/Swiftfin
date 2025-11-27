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

    typealias ContentGroupViewModelPair = (viewModel: any _ContentGroupViewModel, group: any _ContentGroup)

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

    enum State {
        case content
        case error
        case initial
        case refreshing
    }

    @Published
    private(set) var sections: [ContentGroupViewModelPair] = []

    var provider: Provider

    init(provider: Provider) {
        self.provider = provider
        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {

        if sections.isNotEmpty {
            for section in sections {
                try? await section.viewModel.background.refresh()
            }

            return
        }

        func makePair(for group: any _ContentGroup) -> ContentGroupViewModelPair {
            func _makePair(for group: some _ContentGroup) -> ContentGroupViewModelPair {
                (viewModel: group.makeViewModel(), group: group)
            }
            return _makePair(for: group)
        }

        let newGroups = try await provider.makeGroups(environment: provider.environment)
            .map(makePair)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for viewModel in newGroups.map(\.viewModel) {
                group.addTask {
                    try await viewModel.refresh()
                }
            }
            try await group.waitForAll()
        }

        self.sections = newGroups
    }
}
