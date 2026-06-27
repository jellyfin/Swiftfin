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

@MainActor
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

    // Base type (not `ItemLibraryViewModel`, which is `final`) so the People row can use a
    // `/Persons`-backed `FavoritePeopleViewModel` while other rows use `ItemLibraryViewModel`.
    @Published
    private(set) var elements: OrderedDictionary<BaseItemKind, PagingLibraryViewModel<BaseItemDto>> = [:]

    private var task: AnyCancellable?

    private let parent: (any LibraryParent)?
    private let itemTypes: [BaseItemKind]
    // Extra traits AND-ed into every per-kind query — e.g. `[.isFavorite]` / `[.likes]` for the
    // virtual Favorites/Watchlist collections (with a nil parent → a global, server-wide query).
    private let extraTraits: [ItemTrait]
    // Sort applied to every per-kind query. Mutable so the Favorites/Watchlist "Sort" button can change
    // it and re-`refresh`. Defaults match the previous hardcoded behavior (name, ascending).
    var sortBy: [ItemSortBy]
    var sortOrder: [ItemSortOrder]

    init(
        parent: (any LibraryParent)?,
        itemTypes: [BaseItemKind] = BaseItemKind.supportedCases,
        extraTraits: [ItemTrait] = [],
        sortBy: [ItemSortBy] = [ItemSortBy.sortName],
        sortOrder: [ItemSortOrder] = [ItemSortOrder.ascending]
    ) {
        self.parent = parent
        self.itemTypes = itemTypes
        self.extraTraits = extraTraits
        self.sortBy = sortBy
        self.sortOrder = sortOrder
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

    private func getNewElements() async -> OrderedDictionary<BaseItemKind, PagingLibraryViewModel<BaseItemDto>> {
        await withTaskGroup(of: (BaseItemKind, PagingLibraryViewModel<BaseItemDto>).self) { group in
            for kind in itemTypes {
                group.addTask {
                    await (kind, self.getItems(for: kind))
                }
            }

            let newElements = await group.reduce(
                into: OrderedDictionary<BaseItemKind, PagingLibraryViewModel<BaseItemDto>>()
            ) { result, element in
                let (kind, viewModel) = element
                if case .content = viewModel.state, viewModel.elements.isNotEmpty {
                    result[kind] = viewModel
                }
            }

            return newElements.sortedKeys(using: \.rawValue)
        }
    }

    private func getItems(for itemType: BaseItemKind) async -> PagingLibraryViewModel<BaseItemDto> {

        let viewModel: PagingLibraryViewModel<BaseItemDto>
        if itemType == .person, extraTraits.isNotEmpty {
            // Favorited/liked PEOPLE are NOT returned by the generic /Items query the other sections
            // use — they come from /Persons. Only the virtual Favorites/Watchlist collections pass
            // `extraTraits`, so real box-set/person pages are unaffected.
            viewModel = FavoritePeopleViewModel(traits: extraTraits)
        } else {
            /// Server will edit filters if only boxset, add userView as workaround.
            let itemTypes = (itemType == .boxSet ? [.boxSet, .userView] : [itemType])

            viewModel = ItemLibraryViewModel(
                parent: parent,
                filters: .init(itemTypes: itemTypes, sortBy: sortBy, sortOrder: sortOrder, traits: extraTraits),
                pageSize: 20
            )
        }

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

// MARK: - FavoritePeopleViewModel

/// Queries favorited/liked PEOPLE via `/Persons` — they aren't returned by the generic `/Items` query
/// the other collection sections use. Used by the virtual Favorites/Watchlist "Actors" row. `/Persons`
/// returns everything up to `limit` in one shot (no `startIndex` paging), so it's a single page.
final class FavoritePeopleViewModel: PagingLibraryViewModel<BaseItemDto> {

    private let traits: [ItemTrait]

    init(traits: [ItemTrait]) {
        self.traits = traits
        super.init(
            parent: TitledLibraryParent(displayTitle: "People", id: "favorite-people"),
            filters: .init(itemTypes: [.person], traits: traits),
            pageSize: 100
        )
    }

    override func get(page: Int) async throws -> [BaseItemDto] {
        guard page == 0 else { return [] }

        var parameters = Paths.GetPersonsParameters()
        parameters.userID = try authenticatedUser.id
        parameters.limit = 100
        parameters.enableUserData = true
        // Favorites use the dedicated flag; the watchlist ("Likes") goes through the filters array.
        if traits.contains(.isFavorite) {
            parameters.isFavorite = true
        }
        let otherFilters = traits.filter { $0 != .isFavorite }
        if otherFilters.isNotEmpty {
            parameters.filters = otherFilters
        }

        let response = try await send(Paths.getPersons(parameters: parameters))
        // Only people with a headshot, so the row always has artwork (same rule as search).
        return (response.value.items ?? [])
            .filter { $0.imageTags?[ImageType.primary.rawValue]?.isEmpty == false }
    }
}
