//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import IdentifiedCollections
import JellyfinAPI

// MARK: - BrunoShelfViewModel

//
// Type-erases one realized home row. A `BrunoShelf` descriptor's source is backed by the
// appropriate stock paging library (`ResumeItemsLibrary`/`NextUpLibrary`/`RecentlyAddedLibrary`)
// or `BrunoQueryLibrary`, refreshed via `await child.refresh()` (the macro method — never
// `.send`). For `.items` sources (group tiles) the items are used directly. We retain the
// child VM so resume/next-up user-data observers keep working, and republish its `elements`.
@MainActor
final class BrunoShelfViewModel: ObservableObject, Identifiable {

    let shelf: BrunoShelf

    nonisolated var id: String {
        shelf.id
    }

    var lens: String {
        shelf.lens
    }

    var title: String {
        shelf.title
    }

    var posterType: PosterDisplayType {
        shelf.posterType
    }

    @Published
    private(set) var items: IdentifiedArrayOf<BaseItemDto> = []

    private var retainedChild: Any?

    init(shelf: BrunoShelf) {
        self.shelf = shelf
    }

    /// Set items directly, without a network fetch — used to hydrate from the disk cache on launch
    /// and to adopt fresh items into an existing VM during background-revalidate reconcile (keeps
    /// this VM's identity stable so focus survives — INV-2).
    func hydrate(items: [BaseItemDto]) {
        self.items = IdentifiedArray(items, uniquingIDsWith: { existing, _ in existing })
    }

    func load() async {
        switch shelf.source {
        case let .items(items):
            self.items = IdentifiedArray(items, uniquingIDsWith: { existing, _ in existing })
        case .resume:
            await loadPaging(PagingLibraryViewModel(library: ResumeItemsLibrary()))
        case .nextUp:
            await loadPaging(PagingLibraryViewModel(library: NextUpLibrary()))
        case .recentlyAdded:
            await loadPaging(PagingLibraryViewModel(library: RecentlyAddedLibrary()))
        case let .query(query):
            let library = BrunoQueryLibrary(query: query, displayTitle: shelf.title, id: shelf.id)
            await loadPaging(PagingLibraryViewModel(library: library, pageSize: query.limit))
        }
    }

    // Non-generic existential (see `BrunoPagingElements`) so the helper signature is stable
    // under the project's swiftformat pass (a generic `<Library> where ...` gets rewritten).
    private func loadPaging(_ viewModel: any BrunoPagingElements) async {
        retainedChild = viewModel
        await viewModel.refresh()
        items = viewModel.brunoElements
    }

    /// Keep this realized shelf on the home screen? Curated/explore queries need enough items
    /// to read as a row; stock dynamic rows (resume/up-next/new) show whatever they have.
    var shouldDisplay: Bool {
        switch shelf.source {
        case .resume, .nextUp, .recentlyAdded:
            items.isNotEmpty
        case .items:
            items.count >= BrunoHomePlan.minItems
        case .query:
            items.count >= BrunoHomePlan.minItems
        }
    }
}

// MARK: - BrunoPagingElements

/// A non-generic façade over any `PagingLibraryViewModel` whose elements are `BaseItemDto`,
/// so `BrunoShelfViewModel` can hold heterogeneous child VMs without a generic helper.
@MainActor
protocol BrunoPagingElements: AnyObject {
    func refresh() async
    var brunoElements: IdentifiedArrayOf<BaseItemDto> { get }
}

extension PagingLibraryViewModel: BrunoPagingElements where Element == BaseItemDto {
    var brunoElements: IdentifiedArrayOf<BaseItemDto> {
        elements
    }
}
