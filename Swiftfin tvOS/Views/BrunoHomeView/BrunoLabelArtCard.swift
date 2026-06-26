//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - BrunoLabelArtStyle

/// What a `BrunoLabelArtCard` shows AT REST behind its overlaid title (on focus, both styles
/// cross-fade the collection's film art over it — see `BrunoFocusArtCycle`).
enum BrunoLabelArtStyle {
    /// The item's own representative poster, dimmed (Genres sub-collections).
    case poster
    /// A brand gradient (Decades — whose box-set poster has the label baked in, so the poster would
    /// double up with the overlaid title).
    case gradient(top: Color, bottom: Color)
}

// MARK: - BrunoLabelArtCard

//
// A shelf card that renders the category-tile treatment for a single collection item: a controlled
// title (+ accent underline) drawn OVER the art, where the art is the item's poster / a gradient at
// rest and cross-fades the collection's film art while focused. Same poster geometry + two-line title
// reserve as `PosterButton` so it sits byte-identically in a height-pinned shelf row (INV-1) — only
// the card content differs. Used for the Genres and Decades shelves (BrunoShelfRow.labelArt).
struct BrunoLabelArtCard: View {

    let item: BaseItemDto
    let style: BrunoLabelArtStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // `.card` provides `\.isFocused` to this subtree, which BrunoFocusArtCycle reads to
                // cycle film art only while focused — same wiring as BrunoCategoryTile.
                BrunoFocusArtCycle(
                    parentID: item.id,
                    type: .portrait
                ) {
                    restBackground
                } foreground: {
                    label
                }
                .posterStyle(.portrait)

                // Match the poster cards' two-line title area so the row stays aligned (INV-1). The
                // title lives ON the card now, so this reserve is intentionally blank.
                Text(" ")
                    .font(.footnote)
                    .lineLimit(2, reservesSpace: true)
            }
        }
        .buttonStyle(.card)
        .accessibilityLabel(item.displayTitle)
    }

    @ViewBuilder
    private var restBackground: some View {
        ZStack {
            switch style {
            case .poster:
                PosterImage(item: item, type: .portrait)
                    .overlay(Color.black.opacity(0.5)) // dim so the title reads over any poster
            case let .gradient(top, bottom):
                LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
            }

            // Legibility wash where the label sits (matches BrunoCategoryTile).
            LinearGradient(
                colors: [.clear, .black.opacity(0.35)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
    }

    private var label: some View {
        VStack(spacing: 16) {
            Text(item.displayTitle.uppercased())
                .font(.brunoDisplay(38, weight: .bold))
                .foregroundStyle(Color.bruno.fg)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.45)
                .shadow(color: .black.opacity(0.45), radius: 6, y: 2)

            Capsule()
                .fill(Color.bruno.accent)
                .frame(width: 64, height: 5)
        }
        .padding(.horizontal, 24)
    }
}
