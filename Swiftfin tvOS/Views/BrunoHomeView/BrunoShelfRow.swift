//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - BrunoShelfRow

//
// One horizontal shelf with a trailing "Show all" CARD (not a header button — PosterHStack's
// trailing slot is a no-op in this codebase). Lazily renders many items before the Show-all card.
struct BrunoShelfRow: View {

    let items: [BaseItemDto]
    let onItem: (BaseItemDto) -> Void
    let onShowAll: () -> Void

    @FocusState
    private var showAllFocused: Bool

    private enum Card: Identifiable, Hashable {
        case item(BaseItemDto)
        case showAll

        var id: String {
            switch self {
            case let .item(item): item.id ?? item.displayTitle
            case .showAll: "bruno-show-all"
            }
        }
    }

    private var cards: [Card] {
        items.map(Card.item) + [.showAll]
    }

    var body: some View {
        CollectionHStack(
            uniqueElements: cards,
            columns: 7
        ) { card in
            switch card {
            case let .item(item):
                PosterButton(item: item, type: .portrait) {
                    onItem(item)
                } label: {
                    PosterButton<BaseItemDto>.TitleSubtitleContentView(item: item)
                }
            case .showAll:
                showAllCard
            }
        }
        .clipsToBounds(false)
        // Realize only the capped preview set (shelfCap items + the trailing Show-all card).
        // Fewer realized UIHostingController cells per row is the dominant vertical-scroll win.
        .dataPrefix(cards.count)
        .insets(horizontal: EdgeInsets.edgePadding, vertical: 20)
        .itemSpacing(EdgeInsets.edgePadding - 20)
        .scrollBehavior(.continuousLeadingEdge)
        // INV-1: Pin the row height so the LazyVStack never re-reads CollectionHStack's intrinsic size
        // on vertical focus moves. CollectionHStack computes height lazily (throwaway UIHostingController
        // + sizeToFit) and its size.didSet schedules invalidateLayout()+invalidateIntrinsicContentSize()
        // on the NEXT runloop — that cross-frame renegotiation is the up/down focus "hitch"/"math
        // conflict". A constant height removes it from the vertical layout path. Value (portrait poster
        // ~241w x 3/2 + two-line title + 40pt insets) is the single source of truth in BrunoShelfMetrics
        // (see docs/BRUNO_PERF_INVARIANTS.md); clipsToBounds(false) keeps the focus-scaled poster from
        // clipping against this frame.
        .frame(height: BrunoShelfMetrics.shelfRowHeight)
    }

    private var showAllCard: some View {
        Button(action: onShowAll) {
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.bruno.fg.opacity(showAllFocused ? 0.2 : 0.12))

                    // Accent focus ring (matches BrunoSelectorCard / the hero pills) so the card
                    // reads as a deliberate branded affordance, not an inert grey placeholder.
                    if showAllFocused {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.bruno.accent, lineWidth: 3)
                    }

                    VStack(spacing: 10) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 44, weight: .semibold))
                        Text("Show all")
                            .font(.brunoBody(22, weight: .semibold))
                    }
                    .foregroundStyle(Color.bruno.accent)
                }
                .aspectRatio(2.0 / 3.0, contentMode: .fit)

                // Matches the poster cards' two-line title area so the row stays aligned.
                Text(" ")
                    .font(.footnote)
                    .lineLimit(2, reservesSpace: true)
            }
        }
        .buttonStyle(.card)
        .focused($showAllFocused)
    }
}
