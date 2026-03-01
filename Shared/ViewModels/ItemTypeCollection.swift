//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import OrderedCollections

final class ItemTypeCollection: ViewModel, Stateful {

    enum Action {
        case refresh
    }

    enum State: Hashable {
        case content
        case refreshing
    }

    @Published
    var state: State = .content

    @Published
    private(set) var elements: OrderedDictionary<BaseItemKind, ItemLibraryViewModel> = [:]

    private var task: AnyCancellable?

    private let parent: any LibraryParent
    private let itemTypes: [BaseItemKind]

    init(
        parent: any LibraryParent,
        itemTypes: [BaseItemKind] = BaseItemKind.supportedCases
    ) {
        self.parent = parent
        self.itemTypes = itemTypes
    }

    func respond(to action: Action) -> State {
        switch action {
        case .refresh:
            task?.cancel()

            task = Task {
                let newElements = await self.getNewElements()

                await MainActor.run {
                    self.elements = newElements
                    self.state = .content
                }
            }
            .asAnyCancellable()
        }

        return .refreshing
    }

    private func getNewElements() async -> OrderedDictionary<BaseItemKind, ItemLibraryViewModel> {
        await withTaskGroup(of: (BaseItemKind, ItemLibraryViewModel).self) { group in
            for kind in itemTypes {
                group.addTask {
                    await (kind, self.getItems(for: kind))
                }
            }

            let newElements = await group.reduce(
                into: OrderedDictionary<BaseItemKind, ItemLibraryViewModel>()
            ) { result, element in
                let (kind, viewModel) = element
                if case .content = viewModel.state, viewModel.elements.isNotEmpty {
                    result[kind] = viewModel
                }
            }

            return newElements.sortedKeys(using: \.rawValue)
        }
    }

    private func getItems(for itemType: BaseItemKind) async -> ItemLibraryViewModel {

        /// Server will edit filters if only boxset, add userView as workaround.
        let itemTypes = (itemType == .boxSet ? [.boxSet, .userView] : [itemType])

        let viewModel = ItemLibraryViewModel(
            parent: parent,
            filters: .init(itemTypes: itemTypes),
            pageSize: 20
        )

        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = viewModel.$state
                .filter { $0 != .initial && $0 != .refreshing }
                .sink { _ in
                    cancellable?.cancel()
                    continuation.resume(returning: viewModel)
                }

            Task { @MainActor in
                viewModel.send(.refresh)
            }
        }
    }
}
