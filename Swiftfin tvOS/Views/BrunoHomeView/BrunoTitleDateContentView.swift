//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// MARK: - BrunoTitleDateContentView

//
// Bruno-LOCAL poster label: title + full release date. A deliberate, geometry-faithful clone of the
// shared PosterButton.TitleSubtitleContentView (Components/PosterButton.swift:113) so INV-1's pinned
// BrunoShelfMetrics.shelfRowHeight (460) holds with NO height change — same VStack(.leading), same
// title font/opacity, same .lineLimit(1, reservesSpace: true) on BOTH lines. The only divergence is
// line 2: the medium-style premiere date ("May 25, 1977") in place of the (blank-for-movies) subtitle.
// Used by the Decade browse shelves (BrunoShelfRow, showsDate: true) and the Home "New Releases" shelf
// (BrunoShelfView, .recentlyAdded). Do NOT modify the shared view.
struct BrunoTitleDateContentView: View {

    let item: BaseItemDto

    // SINGLE shared formatter. premiereDateLabel allocates a fresh DateFormatter per call, and SwiftUI
    // re-evaluates focused labels often, so a per-cell DateFormatter is a perf trap. .medium → "May 25, 1977".
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var dateString: String {
        guard let premiereDate = item.premiereDate else { return "" }
        return Self.dateFormatter.string(from: premiereDate)
    }

    var body: some View {
        VStack(alignment: .leading) {
            if item.showTitle {
                Text(item.displayTitle)
                    .font(.footnote.weight(.regular))
                    .foregroundColor(.primary)
                    .lineLimit(1, reservesSpace: true)
            }

            Text(dateString)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .lineLimit(1, reservesSpace: true)
        }
    }
}
