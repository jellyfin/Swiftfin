//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - BrunoCategoryTile

//
// The code-drawn artwork for a Collections category navigation tile. Replaces the per-group
// server poster images, which (a) baked the label into the bitmap — so "New Releases" rendered a
// giant "NEW" that we couldn't resize — and (b) left the synthetic "Boxed Sets" category with no
// image at all (the grey placeholder). A code tile draws every label at a CONTROLLED size over a
// per-category gradient + accent underline, matching the existing STUDIOS / SEASONAL banner look.
//
// Pure drawing: no `@FocusState`. The enclosing `Button(...).buttonStyle(.card)` owns focus
// scaling/lift; `posterStyle(.portrait)` gives the poster shape + aspect the card scales.
struct BrunoCategoryTile: View {

    let category: BrunoCollectionCategory

    var body: some View {
        let palette = Self.palette(for: category.name)
        // On focus, dimmed film art from this category cross-fades behind the title; at rest it's the
        // existing branded gradient tile. Portrait art to match the tile shape; children are the
        // fallback art source for synthetic categories (Boxed Sets) whose group BoxSet has no real id.
        BrunoFocusArtCycle(
            parentID: category.boxSet.id,
            fallbackItems: category.children,
            type: .portrait
        ) {
            // At-rest background: a bundled, dimmed category photo over the brand gradient (the
            // gradient is the fallback for art-less categories and a backstop behind each photo).
            // Seasonal is date-gated + slow cross-fades; others swap daily. (On focus, the art cycle
            // above cross-fades server film art over this, unchanged.)
            BrunoCollectionArtBackground(categoryName: category.name, palette: palette)
        } foreground: {
            VStack(spacing: 16) {
                Text(category.name.uppercased())
                    .font(.brunoDisplay(38, weight: .bold))
                    .foregroundStyle(Color.bruno.fg)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    // Controlled sizing: long labels shrink to fit instead of overflowing the tile
                    // (the "giant NEW" fix), short ones still read large.
                    .minimumScaleFactor(0.45)
                    .shadow(color: .black.opacity(0.45), radius: 6, y: 2)

                Capsule()
                    .fill(palette.underline)
                    .frame(width: 64, height: 5)
            }
            .padding(.horizontal, 24)
        }
        .posterStyle(.portrait)
    }

    /// Per-category hue, keyed case-insensitively by group name (unknown names fall back to the
    /// brand accent). Deep top → saturated bottom so white Oswald reads cleanly over it.
    private static func palette(for name: String) -> (top: Color, bottom: Color, underline: Color) {
        switch name.lowercased() {
        case "new releases":
            (Color(hex: "2A1606"), Color(hex: "C25A1E"), Color(hex: "F2802E"))
        case "genres":
            (Color(hex: "1A1026"), Color(hex: "6B3FB0"), Color(hex: "9E6BE0"))
        case "directors":
            (Color(hex: "08191E"), Color(hex: "2E6B7C"), Color(hex: "5BB6CC"))
        case "boxed sets":
            // Cobalt — distinct from the amber Decades tile it sits beside (and every other tile).
            (Color(hex: "0B1430"), Color(hex: "2A45A8"), Color(hex: "5C7CE6"))
        case "decades":
            (Color(hex: "201408"), Color(hex: "9C6A1E"), Color(hex: "E0902E"))
        case "curated":
            (Color(hex: "0C1C0E"), Color(hex: "356B36"), Color(hex: "5FB060"))
        case "studios":
            (Color(hex: "240A12"), Color(hex: "9C2336"), Color(hex: "E03A5A"))
        case "seasonal":
            (Color(hex: "06191E"), Color(hex: "1E7C8C"), Color(hex: "2EB6CC"))
        default:
            (Color.bruno.diplomacyDark, Color.bruno.accentAlt, Color.bruno.accent)
        }
    }
}
