//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import JellyfinAPI
import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - BrunoBoxSetGridView (tvOS only)

//
// "Show all" grid for a flat, already-fetched list of box sets (Boxed Sets in landscape;
// Directors / Studios sub-collections in portrait). A dedicated wrapper over CollectionVGrid — the
// same recycling grid the stock PagingLibraryView uses internally — rather than PagingLibraryView
// itself, because:
//  1. PagingLibraryView's poster style is a user-GLOBAL default; we can't request landscape for
//     just this route without leaking the change to every library.
//  2. We own the cell label (the collection name / "Collection" / film-count + year-range lockup).
//  3. We own the top inset, so the grid sits BELOW the nav title instead of scrolling under it.
struct BrunoBoxSetGridView: View {

    let title: String
    let items: [BaseItemDto]
    let posterType: PosterDisplayType
    /// Boxed Sets only: the "{Title} Collection" / film-count / year-range lockup (+ the year fetch).
    /// Off for Studios/Directors, which are plain name tiles.
    var collectionLabel: Bool = false

    @Router
    private var router

    /// Per-collection release-year ranges (Boxed Sets only), fetched lazily on appear.
    @StateObject
    private var yearRanges = BrunoBoxSetYearRangesViewModel()

    var body: some View {
        grid
            .navigationTitle(title)
            .onFirstAppear {
                if collectionLabel { yearRanges.load(items: items) }
            }
    }

    private var grid: some View {
        CollectionVGrid(
            uniqueElements: items,
            layout: layout
        ) { item in
            PosterButton(item: item, type: posterType) {
                router.route(to: .item(item: item))
            } label: {
                cardLabel(for: item)
            }
        }
        // CollectionVGrid is UIKit-backed and won't re-render cells when the year ranges arrive
        // async; rebuild the grid ONCE when the fetch completes (the @StateObject VM persists, so
        // this doesn't refetch). `done` flips false→true a single time (and stays false when no
        // year fetch runs, e.g. Studios/Directors).
        .id(yearRanges.done)
        .scrollIndicators(.hidden)
    }

    // Mirrors the stock tvOS landscape/portrait grid layout (LibraryElement.layout): 4 columns
    // landscape, 7 portrait, edge-padding insets/spacing.
    private var layout: CollectionVGridLayout {
        let columns = posterType == .landscape ? 4 : 7
        return .columns(
            columns,
            insets: .init(vertical: 0, horizontal: EdgeInsets.edgePadding),
            itemSpacing: EdgeInsets.edgePadding,
            lineSpacing: EdgeInsets.edgePadding
        )
    }

    @ViewBuilder
    private func cardLabel(for item: BaseItemDto) -> some View {
        if posterType == .landscape, collectionLabel {
            BrunoBoxSetCardLabel(item: item, yearRange: yearRanges.ranges[item.id ?? ""])
        } else {
            PosterButton<BaseItemDto>.TitleSubtitleContentView(item: item)
        }
    }
}

// MARK: - BrunoBoxSetCardLabel

//
// The collection card lockup. Preferred layout puts "{Title} Collection" on line 1 and the film
// count (left) + release-year range (right) on line 2. When "{Title} Collection" is too wide for
// one line, `ViewThatFits` falls back: the title alone on line 1, with "Collection" folded into the
// meta line. Each line reserves its height so grid rows stay aligned.
struct BrunoBoxSetCardLabel: View {

    let item: BaseItemDto
    let yearRange: String?

    private var title: String {
        item.displayTitle.brunoStrippingCollectionSuffix
    }

    private var filmCount: String? {
        guard let count = item.childCount, count > 0 else { return nil }
        return count == 1 ? "1 film" : "\(count) films"
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            layout(line1: "\(title) Collection", collectionInMeta: false)
            layout(line1: title, collectionInMeta: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func layout(line1: String, collectionInMeta: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(line1)
                .font(.footnote.weight(.regular))
                .foregroundColor(.primary)
                .lineLimit(1, reservesSpace: true)

            HStack(spacing: 6) {
                Text(metaLeft(collectionInMeta: collectionInMeta))
                Spacer(minLength: 6)
                // Year range sits a step quieter than the film count.
                if let yearRange { Text(yearRange).opacity(0.6) }
            }
            .font(.caption.weight(.medium))
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
    }

    /// Left side of the meta line: the film count, prefixed with "Collection · " only in the
    /// overflow layout where "Collection" couldn't sit on line 1.
    private func metaLeft(collectionInMeta: Bool) -> String {
        let parts = collectionInMeta
            ? ["Collection", filmCount].compactMap(\.self)
            : [filmCount].compactMap(\.self)
        return parts.joined(separator: " · ")
    }
}

// MARK: - BrunoBoxSetYearRangesViewModel

//
// Fetches each box set's release-year RANGE (min–max of its films) concurrently on demand. The box
// set's own `ProductionYear` is only the start; the range needs the children, so we fetch each
// collection's child years once and cache the formatted string. Boxed Sets only (~dozens of items).
@MainActor
final class BrunoBoxSetYearRangesViewModel: ViewModel {

    @Published
    private(set) var ranges: [String: String] = [:]
    /// Flips true once after all ranges are fetched, so the grid can rebuild a single time.
    @Published
    private(set) var done = false

    private var loaded = false

    func load(items: [BaseItemDto]) {
        guard !loaded, let userSession else { return }
        loaded = true
        let client = userSession.client
        let userID = userSession.user.id
        Task {
            await withTaskGroup(of: (String, String)?.self) { group in
                for item in items {
                    guard let id = item.id else { continue }
                    group.addTask { await Self.range(client: client, userID: userID, id: id) }
                }
                for await result in group {
                    if let result { ranges[result.0] = result.1 }
                }
            }
            done = true
        }
    }

    private nonisolated static func range(client: JellyfinClient, userID: String, id: String) async -> (String, String)? {
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userID
        parameters.parentID = id
        parameters.includeItemTypes = [.movie]
        parameters.isRecursive = true
        parameters.limit = 200 // ProductionYear is a base field, returned without an explicit Fields request
        do {
            let items = try await client.send(Paths.getItems(parameters: parameters)).value.items ?? []
            let years = items.compactMap(\.productionYear).filter { $0 > 0 }
            guard let lo = years.min(), let hi = years.max() else { return nil }
            return (id, lo == hi ? "\(lo)" : "\(lo)–\(hi)")
        } catch {
            return nil
        }
    }
}

// MARK: - NavigationRoute

extension NavigationRoute {

    @MainActor
    static func brunoBoxSetGrid(
        title: String,
        items: [BaseItemDto],
        posterType: PosterDisplayType,
        collectionLabel: Bool = false
    ) -> NavigationRoute {
        NavigationRoute(
            id: "bruno-boxset-grid-\(title.lowercased())",
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            BrunoBoxSetGridView(
                title: title,
                items: items,
                posterType: posterType,
                collectionLabel: collectionLabel
            )
        }
    }
}
