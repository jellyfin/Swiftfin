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
import Nuke
import OrderedCollections

/// Sort orders the virtual Favorites/Watchlist collection pages cycle through via the header "Sort"
/// button. Each maps to a server `sortBy` + `sortOrder` and a short display label.
enum MediaCollectionSort: CaseIterable {

    case name
    case releaseYear
    case rating

    var displayTitle: String {
        switch self {
        case .name: "A–Z"
        case .releaseYear: "Release Year"
        case .rating: "Top Rated"
        }
    }

    var sortBy: [ItemSortBy] {
        switch self {
        case .name: [.sortName]
        case .releaseYear: [.premiereDate]
        // Jellyfin's "critic rating" is the Rotten Tomatoes Tomatometer (community rating is the
        // IMDb/user score), so "Top Rated" ranks by Rotten Tomatoes.
        case .rating: [.criticRating]
        }
    }

    var sortOrder: [ItemSortOrder] {
        switch self {
        case .name: [.ascending]
        case .releaseYear, .rating: [.descending]
        }
    }

    var next: MediaCollectionSort {
        let all = Self.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }
}

@MainActor
final class CollectionItemViewModel: ItemViewModel {

    @ObservedPublisher
    var sections: OrderedDictionary<BaseItemKind, PagingLibraryViewModel<BaseItemDto>>

    private let itemCollection: ItemTypeCollection

    /// True for the virtual Favorites / Watchlist collections — a synthetic box-set whose rows come from
    /// a global, trait-filtered query (not a real server item). Used to skip the per-item network fetches.
    let isVirtual: Bool

    /// The Favorites/Watchlist page's current sort order (cycled by the header "Sort" button). Only
    /// meaningful for virtual collections.
    @Published
    private(set) var sortOption: MediaCollectionSort = .name

    /// Advance to the next sort order and re-query every section row in that order.
    func cycleSort() {
        sortOption = sortOption.next
        itemCollection.sortBy = sortOption.sortBy
        itemCollection.sortOrder = sortOption.sortOrder
        itemCollection.send(.refresh)
    }

    // MARK: - Rotating backdrop (virtual collections)

    /// Backdrop-capable items (movies/series with a backdrop) the virtual Favorites/Watchlist page
    /// rotates through, like the home spotlight. Populated ONCE when the sections first load.
    @Published
    private(set) var backdropItems: [BaseItemDto] = []
    @Published
    private(set) var backdropIndex = 0
    private let backdropPrefetcher = ImagePrefetcher()

    var currentBackdropItem: BaseItemDto? {
        guard backdropItems.isNotEmpty else { return nil }
        return backdropItems[min(backdropIndex, backdropItems.count - 1)]
    }

    /// Advance to the next backdrop (wraps). Driven by the view's rotation task.
    func advanceBackdrop() {
        guard backdropItems.count > 1 else { return }
        backdropIndex = (backdropIndex + 1) % backdropItems.count
    }

    /// Warm the NEXT backdrop into the cache so the crossfade is instant (mirrors `SpotlightViewModel`).
    func prefetchNextBackdrop() {
        guard backdropItems.count > 1 else { return }
        let next = (backdropIndex + 1) % backdropItems.count
        if let url = backdropItems[next].imageSource(.backdrop, maxWidth: 1920).url {
            backdropPrefetcher.startPrefetching(with: [url])
        }
    }

    @MainActor
    init(
        item: BaseItemDto,
        itemTypes: [BaseItemKind] = BaseItemKind.supportedCases
            .appending(.episode)
            .appending(.person),
        traits: [ItemTrait] = [],
        isVirtual: Bool = false
    ) {
        self.isVirtual = isVirtual
        self.itemCollection = ItemTypeCollection(
            // Virtual collections query globally (no parent), filtered by `traits`. Default sort is name
            // ascending (A–Z) — the `ItemTypeCollection` default — matching `MediaCollectionSort.name`.
            parent: isVirtual ? nil : item,
            itemTypes: itemTypes,
            extraTraits: traits
        )
        self._sections = ObservedPublisher(
            wrappedValue: [:],
            observing: itemCollection.$elements
        )

        super.init(item: item)

        // Virtual collections: collect the movies/series that have a backdrop (once) so the header can
        // rotate through them like the spotlight. People/episodes are excluded (no landscape backdrop).
        if isVirtual {
            itemCollection.$elements
                .sink { [weak self] elements in
                    guard let self, self.backdropItems.isEmpty else { return }
                    let items = elements.elements
                        .filter { $0.key != .episode && $0.key != .person }
                        .flatMap(\.value.elements)
                        .filter { $0.backdropImageTags?.isNotEmpty == true }
                    if items.isNotEmpty {
                        self.backdropItems = items.shuffled()
                    }
                }
                .store(in: &cancellables)
        }
    }

    /// Builds a virtual collection (Favorites / Watchlist): a synthetic box-set whose rows are a global,
    /// trait-filtered query grouped by type — rendered with the same cinematic collection layout.
    @MainActor
    convenience init(
        virtualCollection title: String,
        id: String,
        itemTypes: [BaseItemKind],
        traits: [ItemTrait]
    ) {
        let placeholder = BaseItemDto(id: id, name: title, type: .boxSet)
        self.init(item: placeholder, itemTypes: itemTypes, traits: traits, isVirtual: true)
    }

    // Virtual collections have no real server item, so skip the item/similar/extras fetches entirely —
    // only the sectioned child query runs.
    override var fetchesFullItem: Bool {
        !isVirtual
    }

    override var fetchesSimilarItems: Bool {
        !isVirtual
    }

    override var fetchesExtras: Bool {
        !isVirtual
    }

    // MARK: - Override Response

    override func respond(to action: ItemViewModel.Action) -> ItemViewModel.State {

        switch action {
        case .refresh, .backgroundRefresh:
            itemCollection.send(.refresh)
        default: ()
        }

        return super.respond(to: action)
    }

    // TODO: possibly multiple items, for image source fallbacks
    func randomItem() -> BaseItemDto? {
        // Try to exclude episodes if possible

        if itemCollection.elements.elements.count == 1 {
            return itemCollection.elements.elements.first?.value.elements.first
        }

        return itemCollection.elements
            .elements
            .shuffled()
            .filter { $0.key != .episode }
            .randomElement()?
            .value
            .elements
            .randomElement()
    }

    // Resolved-once backdrop pick for person/artist/box-set detail pages. `randomItem()` re-rolls on
    // every call (it shuffles), so calling it from a SwiftUI computed property re-randomized the
    // backdrop on EVERY render — causing visible backdrop flicker and redundant image downloads (each
    // new URL was a cache miss). This caches the FIRST non-nil pick so the backdrop stays fixed for the
    // page's lifetime. Not `@Published` — reading/setting it from `body` won't trigger a re-render loop.
    private var cachedRandomBackdrop: BaseItemDto?

    func randomBackdropItem() -> BaseItemDto? {
        if let cachedRandomBackdrop {
            return cachedRandomBackdrop
        }
        let resolved = randomItem()
        // Only persist once the collection has actually produced an item; keep retrying while nil.
        if resolved != nil {
            cachedRandomBackdrop = resolved
        }
        return resolved
    }
}
