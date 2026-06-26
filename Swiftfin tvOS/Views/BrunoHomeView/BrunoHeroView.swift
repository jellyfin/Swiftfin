//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI
import UIKit

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

    /// Eyebrow above the title. "Spotlight" on Home; browse surfaces pass their own ("Featured", …).
    var eyebrow: String = "Spotlight"

    /// The hero is the first scroll row, so bleed the backdrop up under the floating tab bar.
    var bleedsTop: Bool = false

    /// Grow the banner taller (and its bottom edge lower) by this much. A taller banner crops less of
    /// the 16:9 backdrop, so MORE of the source — including its top — survives, and the subject reads
    /// centered below the nav. Home also uses it to restore the space the wordmark row vacated.
    var extraHeight: CGFloat = 0

    /// INV-8: while the home spine is still streaming in, hold the spotlight auto-advance so a
    /// backdrop swap never competes with shelves rising into place (two motion events at once reads
    /// as "busy/loading", not cinematic). The page passes `state == .content` once it has settled.
    var autoAdvanceEnabled: Bool = true

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
            // No `onMoveCommand` on the hero: it's a CONSUMING responder (any direction it "handles",
            // incl. a no-op `default`, suppresses the focus engine's neighbor move), which trapped Up
            // on the hero so focus couldn't rise to the app tab bar — the reported bug (only Settings,
            // which has no hero, let Up through). The spotlight advances via the auto-advance timer +
            // Select; manual left/right spotlight stepping is deferred to a UIKit responder that can
            // step horizontally while letting Up/Down fall through to the focus engine (tracker backlog).
            .onReceive(autoAdvance) { _ in
                // Pause while focused (TV-app behaviour) so the swap never yanks focus, and while the
                // spine is still streaming in (autoAdvanceEnabled — INV-8).
                guard autoAdvanceEnabled, !reduceMotion, !isFocused, items.count > 1 else { return }
                step(by: 1)
            }
        }
    }

    private func heroCard(for item: BaseItemDto) -> some View {
        let insets = UIApplication.shared.brunoOverscanInsets
        let topBleed = bleedsTop ? insets.top : 0
        // Three independent knobs (see swift-reference / hero notes):
        //  • layoutHeight  — the ONLY height the parent VStack measures, so it alone fixes the banner's
        //    bottom edge and the shelves below. extraHeight grows it downward (Home restores the
        //    wordmark-row space the overlay vacated).
        //  • visualHeight  — how tall the backdrop DRAWS. It lives in a `.background` (never measured by
        //    the parent), bottom-pinned to the layout box, so its surplus over layoutHeight spills
        //    UPWARD behind the tab bar — exactly topBleed's worth, landing the source's true top at the
        //    physical screen top (full-bleed top) without moving any sibling.
        //  • imageAnchor   — which slice of the (overflowing) fill survives the crop. .top keeps the
        //    source's true top; .center balances it. Replaces the old magic offset.
        let layoutHeight = 720 + extraHeight
        let visualHeight = layoutHeight + topBleed
        return ZStack(alignment: .bottomLeading) {
            // Left + bottom scrims for legibility (README scrim system), sized to the layout box.
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
                // +overscan keeps the copy title-safe after the card bleeds left to the screen edge.
                    .padding(.leading, 50 + insets.left)
                    .padding(.bottom, 50)
                    .padding(.trailing, 600)
        }
        .frame(maxWidth: .infinity)
        .frame(height: layoutHeight)
        .background(alignment: .bottom) {
            // The drawn backdrop: taller than the layout box, bottom-pinned so the surplus spills up
            // behind the nav. A page-color fill reserves the frame from first render (anti-jump).
            ZStack(alignment: imageAnchor) {
                Color.bruno.page
                ImageView(item.imageSource(.backdrop, maxWidth: 1920))
                    .aspectRatio(contentMode: .fill)
            }
            .frame(maxWidth: .infinity)
            .frame(height: visualHeight, alignment: imageAnchor)
            .clipped()
            .id(item.id)
            .transition(.opacity)
        }
        // Full-bleed horizontally: negate the ScrollView's title-safe content inset so the backdrop +
        // scrims reach the physical screen edges. (Top bleed is produced by visualHeight spilling up.)
        .padding(.horizontal, -insets.left)
    }

    /// Which vertical slice of the filled backdrop survives the crop. `.top` shows the source's true
    /// top (subjects sit lower, clear of the nav); `.center` balances top and bottom.
    private var imageAnchor: Alignment {
        .top
    }

    @ViewBuilder
    private func content(for item: BaseItemDto) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(eyebrow.uppercased())
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

// MARK: - Overscan

extension UIApplication {

    /// The key window's tvOS title-safe overscan insets. The page ScrollView insets its content to
    /// this, so Bruno's full-bleed hero negates it to reach the physical screen edges; the Home
    /// wordmark (overlaid on the top-bleeding hero) re-applies it to stay title-safe.
    var brunoOverscanInsets: UIEdgeInsets {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .safeAreaInsets ?? .zero
    }
}
