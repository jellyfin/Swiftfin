//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

private let landscapeMaxWidth: CGFloat = 500
private let portraitMaxWidth: CGFloat = 500

struct PosterButton<Item: Poster>: View {

    @EnvironmentTypeValue<Item>(\.posterOverlayRegistry)
    private var posterOverlayRegistry

    @EnvironmentTypeValue<Item>(\.posterTopBannerRegistry)
    private var posterTopBannerRegistry

    @State
    private var posterSize: CGSize = .zero

    @Default(.Customization.Indicators.showProgress)
    private var showProgress

    private var horizontalAlignment: HorizontalAlignment
    private let item: Item
    private let type: PosterDisplayType
    private let label: any View
    private let action: () -> Void

    private var baseItem: BaseItemDto? {
        item as? BaseItemDto
    }

    /// Fraction (0–1) watched, for the hanging Continue Watching bar.
    private var progressValue: CGFloat {
        CGFloat((baseItem?.userData?.playedPercentage ?? 0) / 100)
    }

    /// Show the hanging Continue Watching bar only for in-progress items using the default
    /// overlay. Custom poster overlays (e.g. the cinematic resume row) draw their own progress.
    private var showsHangingProgressBar: Bool {
        guard showProgress, posterOverlayRegistry == nil, let baseItem else { return false }
        let isPlayed = baseItem.canBePlayed && !baseItem.isLiveStream && baseItem.userData?.isPlayed == true
        guard !isPlayed else { return false }
        return (baseItem.userData?.playbackPositionTicks ?? 0) > 0
    }

    /// Height of the visible portion of the Continue Watching bar that hangs below the poster.
    private static var progressBarHeight: CGFloat {
        7
    }

    /// Matches `posterCornerRadius(_:)`'s ratios so the hanging bar rounds its bottom corners
    /// by the same amount as the poster.
    private static func cornerRadiusRatio(for type: PosterDisplayType) -> CGFloat {
        switch type {
        case .landscape: 1 / 30
        case .portrait, .square: 0.0375
        }
    }

    @ViewBuilder
    private func poster(overlay: some View) -> some View {
        PosterImage(item: item, type: type)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay { overlay }
            .contentShape(.contextMenuPreview, Rectangle())
            .posterStyle(type)
            .posterCornerRadius(type)
        // NOTE: the drop shadow is applied to the whole card group in `body` (poster + hanging
        // bar), not here, so for Continue Watching cards it falls below the progress bar instead
        // of onto it.
    }

    var body: some View {
        Button(action: action) {
            let overlay = posterOverlayRegistry?(item) ??
                PosterButton.DefaultOverlay(item: item)
                .eraseToAnyView()

            let cornerRadius = Self.cornerRadiusRatio(for: type) * posterSize.width

            VStack(alignment: .leading, spacing: 4) {
                // Poster keeps its normal look (all four corners rounded). The Continue Watching
                // bar hangs below it, and also extends up behind the poster by `cornerRadius` so
                // it fills the notches left by the poster's rounded bottom corners (no gap).
                //
                // Liquid Glass (`glassEffect`) is applied to the POSTER ONLY (and only while
                // focused) — it adds no scale of its own, so it never touches or desyncs the label.
                poster(overlay: overlay)
                    .trackingSize($posterSize)
                    // A flush-top banner ("UPCOMING" / "REQUEST?") drawn OVER the poster's corner clip,
                    // with its own top-rounded / bottom-FLAT shape so the bottom edge never curves — even
                    // when the poster's corner radius is larger than the banner is tall. Its height is at
                    // least `cornerRadius` so the top rounding fully matches the poster's corners (no
                    // overhang). Anchored to the poster only, so the focus scale still carries it.
                    .overlay(alignment: .top) {
                        if let topBanner = posterTopBannerRegistry?(item) {
                            topBanner
                                .frame(maxWidth: .infinity)
                                .frame(height: max(26, cornerRadius))
                                .clipShape(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: cornerRadius,
                                        bottomLeadingRadius: 0,
                                        bottomTrailingRadius: 0,
                                        topTrailingRadius: cornerRadius,
                                        style: .continuous
                                    )
                                )
                        }
                    }
                    .modifier(PosterFocusGlass(cornerRadius: cornerRadius))
                    .padding(.bottom, showsHangingProgressBar ? Self.progressBarHeight : 0)
                    .background(alignment: .bottom) {
                        if showsHangingProgressBar {
                            HangingProgressBar(
                                progress: progressValue,
                                cornerRadius: cornerRadius
                            )
                            .frame(height: Self.progressBarHeight + cornerRadius)
                        }
                    }
                    .posterShadow()

                label
                    .eraseToAnyView()
                    // One legibility treatment for EVERY poster label (home, search, collection/actor,
                    // "More Like This", library grids) — see `posterLabelShadow()`. Applied here so each
                    // label site doesn't have to (and can't double up).
                    .posterLabelShadow()
            }
        }
        // A single custom scale grows the WHOLE lockup (poster + label) together on focus, so the
        // label grows perfectly in sync with the poster, with no overlap and no glass/background on
        // the label. The Liquid Glass focus visual lives on the poster only (see PosterFocusGlass).
        .buttonStyle(PosterFocusScaleStyle())
        .focusedValue(\.focusedPoster, AnyPoster(item))
        .accessibilityLabel(item.displayTitle)
        .matchedContextMenu(for: item) {
            EmptyView()
        }
    }
}

/// Scales the whole poster lockup (poster + label) up slightly on focus, so the label grows in
/// perfect sync with the poster and the spacing between them is preserved (no overlap). No glass
/// or shadow — just a cheap GPU transform; the focus glass lives on the poster (`PosterFocusGlass`).
private struct PosterFocusScaleStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        Content(configuration: configuration)
    }

    private struct Content: View {

        @Environment(\.isFocused)
        private var isFocused

        let configuration: ButtonStyleConfiguration

        var body: some View {
            configuration.label
                .scaleEffect(isFocused ? 1.08 : 1)
                .animation(.easeOut(duration: 0.2), value: isFocused)
        }
    }
}

/// A glass-style focus rim on the poster: a rounded-rect stroke with a top-down white sheen (like
/// light catching a glass edge) that **fades in via opacity** on focus, shaped to the poster's
/// corners. Adds no scale (the lockup scale handles growth) so it can't desync or touch the label.
///
/// Why not the system `glassEffect`: applying that effect only-while-focused *adds it to the view
/// hierarchy* on focus, so SwiftUI plays its built-in "materialize" transition — a split-second
/// scale/specular shimmer (the "flash"). An opacity fade has no such transition, so this is
/// flash-free while still reading as glass.
private struct PosterFocusGlass: ViewModifier {

    let cornerRadius: CGFloat

    @Environment(\.isFocused)
    private var isFocused

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.85), .white.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .opacity(isFocused ? 1 : 0)
            }
            .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}

/// The Continue Watching progress bar that hangs below the poster. It is given a frame taller
/// than its visible height: the top `cornerRadius` sits behind the poster to fill the notches
/// left by the poster's rounded bottom corners, while the rest hangs below. Its bottom corners
/// are rounded to match the poster and its top is square so the notches fill completely.
private struct HangingProgressBar: View {

    @Default(.accentColor)
    private var accentColor

    let progress: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                // Unfilled track
                Color.white.opacity(0.25)

                // Watched portion
                accentColor
                    .frame(width: proxy.size.width * progress)
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius
            )
        )
    }
}

extension PosterButton {

    init(
        item: Item,
        type: PosterDisplayType,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> any View
    ) {
        self.item = item
        self.type = type
        self.action = action
        self.label = label()
        self.horizontalAlignment = .leading
    }

    func horizontalAlignment(_ alignment: HorizontalAlignment) -> Self {
        copy(modifying: \.horizontalAlignment, with: alignment)
    }
}

// TODO: Shared default content with iOS?
//       - check if content is generally same

extension PosterButton {

    // MARK: Default Content

    struct TitleContentView: View {

        let item: Item

        var body: some View {
            Text(item.displayTitle)
                .font(.footnote.weight(.regular))
                .foregroundColor(.white)
                .accessibilityLabel(item.displayTitle)
        }
    }

    struct SubtitleContentView: View {

        let item: Item

        var body: some View {
            Text(item.subtitle ?? "")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
    }

    struct TitleSubtitleContentView: View {

        let item: Item

        var body: some View {
            VStack(alignment: .leading) {
                if item.showTitle {
                    TitleContentView(item: item)
                        .lineLimit(1, reservesSpace: true)
                }

                SubtitleContentView(item: item)
                    .lineLimit(1, reservesSpace: true)
            }
        }
    }

    // TODO: clean up

    // Content specific for BaseItemDto episode items
    struct EpisodeContentSubtitleContent: View {

        let item: Item

        var body: some View {
            if let item = item as? BaseItemDto {
                // Unsure why this needs 0 spacing
                // compared to other default content
                VStack(alignment: .leading, spacing: 0) {
                    if item.showTitle, let seriesName = item.seriesName {
                        Text(seriesName)
                            .font(.footnote.weight(.regular))
                            .foregroundColor(.primary)
                            .lineLimit(1, reservesSpace: true)
                    }

                    Subtitle(item: item)
                }
            }
        }

        struct Subtitle: View {

            let item: BaseItemDto

            var body: some View {

                SeparatorHStack {
                    Circle()
                        .frame(width: 2, height: 2)
                        .padding(.horizontal, 3)
                } content: {
                    SeparatorHStack {
                        Text(item.seasonEpisodeLabel ?? .emptyDash)

                        if item.showTitle {
                            Text(item.displayTitle)

                        } else if let seriesName = item.seriesName {
                            Text(seriesName)
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
        }
    }

    struct DefaultOverlay: View {

        @Default(.Customization.Indicators.showPlayed)
        private var showPlayed

        @Default(.Customization.Indicators.showFavorited)
        private var showFavorited

        @Environment(\.isFocused)
        private var isFocused

        let item: Item

        private var baseItem: BaseItemDto? {
            item as? BaseItemDto
        }

        private var isPlayed: Bool {
            guard let baseItem else { return false }
            return baseItem.canBePlayed && !baseItem.isLiveStream && baseItem.userData?.isPlayed == true
        }

        var body: some View {
            // NOTE: the Continue Watching progress bar is no longer drawn here — it now hangs
            // below the poster (see PosterButton.HangingProgressBar). This overlay only carries
            // the watched checkmark and favorite heart.
            ZStack {
                Color.clear
            }
            // Watched: a plain white checkmark, no background.
            .overlay(alignment: .bottomTrailing) {
                if showPlayed, isPlayed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 3)
                        .padding(12)
                }
            }
            // Favorite: a red heart that fades in only while focused, no background.
            .overlay(alignment: .topTrailing) {
                if showFavorited, baseItem?.userData?.isFavorite == true {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.red)
                        .shadow(color: .black.opacity(0.6), radius: 3)
                        .padding(12)
                        .opacity(isFocused ? 1 : 0)
                        .animation(.easeInOut(duration: 0.25), value: isFocused)
                }
            }
        }
    }
}
