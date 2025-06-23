//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections

final class PersonItemViewModel: ItemViewModel {

    // MARK: - Published Collection Items

    @Published
    private(set) var personItems: OrderedDictionary<BaseItemKind, ItemLibraryViewModel> = [:]

    // MARK: - Task

    private var personItemTask: AnyCancellable?
    private var initializationTask: AnyCancellable?

    // MARK: - Disable PlayButton

    override var presentPlayButton: Bool {
        false
    }

    // MARK: - Disable Play Toggle

    override var canBePlayed: Bool {
        false
    }

    // MARK: - Override Response

    override func respond(to action: ItemViewModel.Action) -> ItemViewModel.State {

        switch action {
        case .refresh, .backgroundRefresh:
            personItemTask?.cancel()

            personItemTask = Task {
                let personItems = await self.getPersonViewModels()

                await MainActor.run {
                    self.personItems = personItems
                }
            }
            .asAnyCancellable()
        default: ()
        }

        return super.respond(to: action)
    }

    // MARK: - Get Person ItemLibraryViewModels

    private func getPersonViewModels() async -> OrderedDictionary<BaseItemKind, ItemLibraryViewModel> {
        guard item.id != nil else {
            return [:]
        }

        var allViewModels: [BaseItemKind: ItemLibraryViewModel] = [:]
        var completedViewModels: [BaseItemKind: ItemLibraryViewModel] = [:]

        for itemKind in BaseItemKind.supportedCases {
            let viewModel = ItemLibraryViewModel(
                parent: item,
                filters: .init(itemTypes: [itemKind])
            )
            allViewModels[itemKind] = viewModel
        }

        await withTaskGroup(of: (BaseItemKind, Bool).self) { group in
            for (kind, viewModel) in allViewModels {
                group.addTask {
                    await withCheckedContinuation { continuation in
                        var cancellable: AnyCancellable?

                        cancellable = viewModel.$state
                            .sink { state in
                                if state != .initial && state != .refreshing {
                                    cancellable?.cancel()
                                    continuation.resume(returning: (kind, state == .content))
                                }
                            }

                        Task { @MainActor in
                            viewModel.send(.refresh)
                        }
                    }
                }
            }

            for await (kind, isSuccess) in group {
                if isSuccess, let viewModel = allViewModels[kind], !viewModel.elements.isEmpty {
                    completedViewModels[kind] = viewModel
                }
            }
        }

        return OrderedDictionary(
            uniqueKeysWithValues: completedViewModels.sorted { $0.key.rawValue < $1.key.rawValue }
        )
    }
}
