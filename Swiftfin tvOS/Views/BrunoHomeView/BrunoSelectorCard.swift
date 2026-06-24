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

// MARK: - BrunoSelectorCard

//
// A landscape selector tile styled to match the home page's landscape movie cards: a 16:9 rounded
// card with the stock tvOS `.card` focus lift. Used for category / filter pickers (the Genres core
// panel, the Kids filter) in place of small pills, so selectors read as cards like the rest of the
// browse surface. Title-in-card (no art) since these are text buckets, not media items.
struct BrunoSelectorCard: View {

    let title: String
    var isSelected: Bool = false
    var width: CGFloat = 340
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.bruno.accent : Color.bruno.diplomacyBrown)

                Text(title)
                    .font(.brunoBody(30, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.bruno.page : Color.bruno.fg)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .padding(.horizontal, 20)
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .frame(width: width)
        }
        .buttonStyle(.card)
    }
}
