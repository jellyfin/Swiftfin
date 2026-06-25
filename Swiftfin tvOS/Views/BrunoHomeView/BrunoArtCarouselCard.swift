//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// MARK: - BrunoArtCarouselCard (tvOS only)

//
// A poster card for the Studios / Directors grids that, WHILE FOCUSED, swaps its static art (studio
// logo / director headshot) for a carousel of the collection's movie art, cross-fading every 2s; on
// unfocus it reverts to the static art. Mirrors PosterButton's button structure (PosterImage isn't
// injectable, so we rebuild the thin shell) so focus scale / shadow / zoom-push behave identically —
// only the image content differs.
//
// Gated to Studios + Directors; Boxed Sets keep the plain PosterButton.
struct BrunoArtCarouselCard<Label: View>: View {

    let item: BaseItemDto
    let type: PosterDisplayType
    let action: () -> Void
    @ViewBuilder
    let label: () -> Label

    var body: some View {
        Button(action: action) {
            FocusCyclingArt(item: item, type: type)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.contextMenuPreview, Rectangle())
                .posterStyle(type)
                .posterShadow()
                .hoverEffect(.highlight)

            label()
        }
        .buttonStyle(.borderless)
        .buttonBorderShape(.roundedRectangle)
        .accessibilityLabel(item.displayTitle)
    }
}

// MARK: - FocusCyclingArt

//
// The card's image area. Reads the enclosing card's focus via `\.isFocused`. On focus it lazily
// loads the collection's films and (after a brief hold) cross-fades through their art; on unfocus it
// reverts to the static card art. Only the focused card runs a cycle task (started on focus,
// cancelled on unfocus/disappear). Respects Reduce Motion (stays on the static art, no auto-advance).
//
// Behaviour notes:
//  • HOLD: a 2s pause after focus shows the card AS-IS first, so a quick pass-through doesn't flash.
//  • NO-GAP: all frames are prefetched into the Nuke memory cache on load (BrunoPosterPrefetcher,
//    same pipeline + request width as the cells), so each swap reads from cache — no blank between.
//  • FILL: landscape cards use the films' 16:9 art (Thumb/Backdrop) and portrait cards use posters,
//    each `.fill` — so the art fills the card with no letterbox wings and minimal crop.
private struct FocusCyclingArt: View {

    let item: BaseItemDto
    let type: PosterDisplayType

    @Environment(\.isFocused)
    private var isFocused
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @StateObject
    private var children = BrunoChildArtViewModel()
    @State
    private var index = 0
    /// Flips true only after the post-focus hold elapses; gates the carousel on/off.
    @State
    private var rolling = false
    @State
    private var cycle: Task<Void, Never>?

    private static let holdSeconds: Double = 2
    private static let frameSeconds: Double = 2

    /// Show film art only once the hold has elapsed AND frames have loaded; otherwise the static art.
    private var active: Bool {
        rolling && !children.frames.isEmpty
    }

    var body: some View {
        ZStack {
            // Backing for the brief moment before the first frame resolves.
            Color.bruno.surface

            PosterImage(item: item, type: type)
                .opacity(active ? 0 : 1)

            if active, let frame = children.frames[safe: index] {
                ImageView(frame)
                    .aspectRatio(contentMode: .fill)
                    .id(index)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: reduceMotion ? 0 : 0.35), value: index)
        .animation(.easeInOut(duration: reduceMotion ? 0 : 0.3), value: active)
        .onChange(of: isFocused) { _, focused in
            if focused {
                index = 0
                rolling = false
                children.load(item: item, type: type)
                startCycle()
            } else {
                stopCycle()
            }
        }
        .onDisappear(perform: stopCycle)
    }

    private func startCycle() {
        stopCycle()
        guard !reduceMotion else { return }
        cycle = Task { @MainActor in
            // (1) Hold: show the card as-is so a quick focus pass doesn't flash the carousel.
            try? await Task.sleep(for: .seconds(Self.holdSeconds))
            if Task.isCancelled { return }
            rolling = true
            // (2) Advance one frame every `frameSeconds`; frames are pre-warmed so swaps are instant.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.frameSeconds))
                if Task.isCancelled { return }
                let count = children.frames.count
                guard count > 1 else { continue }
                index = (index + 1) % count
            }
        }
    }

    private func stopCycle() {
        cycle?.cancel()
        cycle = nil
        rolling = false
        children.stopPrefetch()
    }
}

// MARK: - BrunoChildArtViewModel

//
// Loads a collection's child-film art once (cached) on first focus, and prefetches every frame into
// the Nuke memory cache so the carousel never shows a gap. Random order so it varies between visits.
// Frames are type-matched to the card: landscape (Thumb/Backdrop) for landscape cards, posters for
// portrait — built at the SAME request width the prefetcher warms, so the cache keys line up (INV-4).
@MainActor
final class BrunoChildArtViewModel: ViewModel {

    /// One ordered ImageSource list per film (fallback chain), already type-matched.
    @Published
    private(set) var frames: [[ImageSource]] = []

    private let prefetcher = BrunoPosterPrefetcher()
    private var warmed: [BaseItemDto] = []
    private var warmedType: PosterDisplayType = .portrait
    private var loaded = false

    func load(item: BaseItemDto, type: PosterDisplayType) {
        guard !loaded, let parentID = item.id, let userSession else { return }
        loaded = true
        warmedType = type
        let client = userSession.client
        let userID = userSession.user.id
        let width = BrunoShelfMetrics.posterMaxWidth(for: type)
        let quality = BrunoShelfMetrics.posterQuality
        Task {
            var parameters = Paths.GetItemsParameters()
            parameters.userID = userID
            parameters.parentID = parentID
            parameters.includeItemTypes = [.movie]
            parameters.isRecursive = true
            parameters.sortBy = [ItemSortBy.random]
            // Cap to the prefetcher's warm window so every shown frame is pre-warmed.
            parameters.limit = 10
            do {
                let items = try await client.send(Paths.getItems(parameters: parameters)).value.items ?? []
                let usable = items.filter { item in
                    sources(for: item, type: type, width: width, quality: quality).contains { $0.url != nil }
                }
                warmed = usable
                frames = usable.map { sources(for: $0, type: type, width: width, quality: quality) }
                prefetcher.warm(usable, type: type)
            } catch {}
        }
    }

    func stopPrefetch() {
        prefetcher.stop(warmed, type: warmedType)
    }

    private func sources(
        for item: BaseItemDto,
        type: PosterDisplayType,
        width: CGFloat,
        quality: Int
    ) -> [ImageSource] {
        type == .landscape
            ? item.landscapeImageSources(maxWidth: width, quality: quality)
            : item.portraitImageSources(maxWidth: width, quality: quality)
    }
}
