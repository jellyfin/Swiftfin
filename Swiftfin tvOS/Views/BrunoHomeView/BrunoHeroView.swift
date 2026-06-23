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

// MARK: - BrunoHeroView

//
// The rotating spotlight: a seeded 5-item feature (the seed pool comes from the view model,
// plan §D). Full-bleed backdrop + left scrim, Oswald title, meta, and Play / More Info that
// route to the stock item detail (Play-for-the-proto, plan §C4). Dots switch the spotlight.
struct BrunoHeroView: View {

    let items: [BaseItemDto]

    @Router
    private var router

    @State
    private var index = 0

    private var current: BaseItemDto? {
        items[safe: index] ?? items.first
    }

    var body: some View {
        if let current {
            ZStack(alignment: .bottomLeading) {
                ImageView(current.imageSource(.backdrop, maxWidth: 1920))
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 720)
                    .clipped()

                // Left + bottom scrims for legibility (README scrim system).
                LinearGradient(
                    colors: [Color.bruno.page.opacity(0.96), Color.bruno.page.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                LinearGradient(
                    colors: [Color.bruno.page, .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )

                content(for: current)
                    .padding(.leading, 50)
                    .padding(.bottom, 50)
                    .padding(.trailing, 600)
            }
            .frame(height: 720)
        }
    }

    @ViewBuilder
    private func content(for item: BaseItemDto) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Spotlight".uppercased())
                .font(.brunoBody(18, weight: .semibold))
                .tracking(5)
                .foregroundStyle(Color.bruno.accent)

            Text(item.displayTitle)
                .font(.brunoDisplay(72, weight: .semibold))
                .foregroundStyle(Color.bruno.fg)
                .lineLimit(2)

            Text(metaLine(for: item))
                .font(.brunoBody(22))
                .foregroundStyle(Color.bruno.fgMuted)

            if let overview = item.overview {
                Text(overview)
                    .font(.brunoBody(22))
                    .foregroundStyle(Color.bruno.fgMuted)
                    .lineLimit(3)
            }

            HStack(spacing: 18) {
                Button {
                    router.route(to: .item(item: item))
                } label: {
                    Label("Play", systemImage: "play.fill")
                        .font(.brunoBody(24, weight: .semibold))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.card)

                Button {
                    router.route(to: .item(item: item))
                } label: {
                    Label("More Info", systemImage: "info.circle")
                        .font(.brunoBody(24, weight: .semibold))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.card)
            }
            .padding(.top, 6)

            if items.count > 1 {
                HStack(spacing: 10) {
                    ForEach(Array(items.enumerated()), id: \.offset) { offset, _ in
                        Button {
                            index = offset
                        } label: {
                            Circle()
                                .fill(offset == index ? Color.bruno.accent : Color.bruno.fgSubtle.opacity(0.4))
                                .frame(width: 14, height: 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func metaLine(for item: BaseItemDto) -> String {
        var parts: [String] = []
        if let year = item.productionYear { parts.append(String(year)) }
        if let genre = item.genres?.first { parts.append(genre) }
        if let rating = item.communityRating { parts.append("★ \(String(format: "%.1f", rating))") }
        return parts.joined(separator: "  ·  ")
    }
}
