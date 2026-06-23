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
// plan §D). Full-bleed backdrop + left scrim, Oswald title, meta, and a Play / More-Info hint
// that routes to the stock item detail (Play-for-the-proto, plan §C4).
//
// Focus model (Apple-TV-app feel): the whole hero is ONE chrome-less focusable element — a
// click down from the top menu lands on it with no button highlight. Left/right move commands
// cycle the spotlight like a content shelf (the dots are a passive page indicator, not
// focusable buttons). Select opens the spotlight item. Auto-advance pauses while focused so the
// backdrop never swaps focus out from under the user.
struct BrunoHeroView: View {

    let items: [BaseItemDto]

    /// Bound so the home's ambient backdrop can track the selected spotlight.
    @Binding
    var index: Int

    @Router
    private var router

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @FocusState
    private var isFocused: Bool

    /// Auto-advance cadence for the spotlight (paused while focused).
    private let autoAdvance = Timer.publish(every: 8, on: .main, in: .common).autoconnect()

    private var current: BaseItemDto? {
        items[safe: index] ?? items.first
    }

    var body: some View {
        if let current {
            Button {
                router.route(to: .item(item: current))
            } label: {
                heroCard(for: current)
            }
            .buttonStyle(BrunoHeroButtonStyle())
            .focused($isFocused)
            .onMoveCommand { direction in
                switch direction {
                case .left:
                    step(by: -1)
                case .right:
                    step(by: 1)
                default:
                    break
                }
            }
            .onReceive(autoAdvance) { _ in
                // Pause while focused (TV-app behaviour) so the swap never yanks focus.
                guard !reduceMotion, !isFocused, items.count > 1 else { return }
                step(by: 1)
            }
        }
    }

    private func heroCard(for item: BaseItemDto) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop layer: a placeholder fill reserves the full 720×width frame from the first
            // render (the image then fills within those fixed bounds), so the ImageView's (zero)
            // intrinsic size can't drive layout until it loads — which made the whole home "lift
            // then reset" on the very first load. Clipping is scoped to THIS layer so a tall
            // title/overview is never clipped.
            ZStack {
                Color.bruno.page

                ImageView(item.imageSource(.backdrop, maxWidth: 1920))
                    .aspectRatio(contentMode: .fill)
                    // Keyed on the item id (ImageView caches its source in @State and ignores
                    // later parent updates) so the backdrop actually re-fetches each cycle; the
                    // opacity transition cross-fades the swap instead of hard-cutting.
                    .id(item.id)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity)
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

            content(for: item)
                .padding(.leading, 50)
                .padding(.bottom, 50)
                .padding(.trailing, 600)
        }
        .frame(height: 720)
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

            // Non-focusable affordances: the hero itself is the focus target, so these are
            // hints for what Select does — they brighten while the hero is focused.
            HStack(spacing: 18) {
                heroPill("Play", systemImage: "play.fill", prominent: true)
                heroPill("More Info", systemImage: "info.circle", prominent: false)
            }
            .padding(.top, 6)

            if items.count > 1 {
                HStack(spacing: 10) {
                    ForEach(items.indices, id: \.self) { offset in
                        Circle()
                            .fill(offset == index ? Color.bruno.accent : Color.bruno.fgSubtle.opacity(0.4))
                            .frame(width: 14, height: 14)
                    }
                }
                .padding(.top, 8)
                .accessibilityHidden(true)
            }
        }
    }

    private func heroPill(_ title: String, systemImage: String, prominent: Bool) -> some View {
        Label(title, systemImage: systemImage)
            .font(.brunoBody(24, weight: .semibold))
            .foregroundStyle(prominent && isFocused ? Color.bruno.page : Color.bruno.fg)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(
                        prominent
                            ? (isFocused ? Color.bruno.accent : Color.bruno.fg.opacity(0.18))
                            : Color.bruno.fg.opacity(0.12)
                    )
            }
    }

    private func step(by delta: Int) {
        guard items.count > 1 else { return }
        let count = items.count
        let next = ((index + delta) % count + count) % count
        withAnimation(.easeInOut(duration: 0.45)) {
            index = next
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

// MARK: - BrunoHeroButtonStyle

//
// A chrome-less button style: no scale, no system focus halo. The hero communicates focus
// through its own affordances (the brightened Play pill) instead of a card highlight, so a
// click down from the menu "invisibly" lands on the hero.
private struct BrunoHeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
