//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// MARK: - BrunoFocusArtCycle (tvOS only)

//
// Reusable focus treatment: a card/tile that, WHILE FOCUSED, cross-fades DIMMED artwork (a random
// sample of films under `parentID`, or `fallbackItems` for synthetic categories) BEHIND a fully
// static foreground (title, logo, …); at rest it shows just `background`. Drop on any focusable
// surface — the group tiles here, and other systems later.
//
// Design rules (from owner feedback):
//   • Art is type-matched to the CARD shape (`type`) and constrained to the card frame — a portrait
//     tile cycles portrait art and never bleeds into a landscape rectangle.
//   • The foreground is STATIC — only the art layer animates. No `.animation` touches the title.
//   • Frame-to-frame is a true two-layer cross-dissolve (new frame opaque underneath, old fades out
//     on top), so there's no dip to black between frames.
//
// Perf-safe by construction: reads `\.isFocused` so ONLY the focused card cycles; a brief hold before
// the first frame; frames prefetched into the Nuke memory cache (BrunoPosterPrefetcher, same pipeline
// + width as the cells) so swaps never gap; cycle task cancelled on unfocus/disappear; Reduce Motion
// holds the static background.
struct BrunoFocusArtCycle<Background: View, Foreground: View>: View {

    private let parentID: String?
    private let fallbackItems: [BaseItemDto]
    private let type: PosterDisplayType
    private let dim: Double
    private let background: () -> Background
    private let foreground: () -> Foreground

    init(
        parentID: String?,
        fallbackItems: [BaseItemDto] = [],
        type: PosterDisplayType = .portrait,
        dim: Double = 0.55,
        @ViewBuilder background: @escaping () -> Background,
        @ViewBuilder foreground: @escaping () -> Foreground
    ) {
        self.parentID = parentID
        self.fallbackItems = fallbackItems
        self.type = type
        self.dim = dim
        self.background = background
        self.foreground = foreground
    }

    @Environment(\.isFocused)
    private var isFocused
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @StateObject
    private var art = BrunoArtCycleViewModel()
    @State
    private var index = 0
    /// The outgoing frame's index, rendered on TOP of the (opaque) current frame and faded to 0 — the
    /// seamless dissolve: the new frame is already fully painted underneath, so nothing dips to black.
    @State
    private var fadingIndex: Int?
    @State
    private var fadeOpacity: Double = 0
    @State
    private var rolling = false
    @State
    private var cycle: Task<Void, Never>?

    private static var holdSeconds: Double {
        1.5
    }

    private static var frameSeconds: Double {
        1.25
    }

    private static var dissolveSeconds: Double {
        0.55
    }

    private var active: Bool {
        rolling && !art.frames.isEmpty
    }

    var body: some View {
        ZStack {
            background()

            // Art layer — the ONLY animated part. Fades in over the gradient once active.
            if active {
                ZStack {
                    if let current = art.frames[safe: index] {
                        frame(current, key: index) // current frame, opaque, underneath
                    }
                    if let fadingIndex, let fading = art.frames[safe: fadingIndex] {
                        frame(fading, key: fadingIndex).opacity(fadeOpacity) // previous frame, fading out on top
                    }
                }
                .transition(.opacity)
            }

            foreground() // STATIC — no animation reaches it
        }
        .clipped()
        .onChange(of: isFocused) { _, focused in
            if focused {
                index = 0
                fadingIndex = nil
                fadeOpacity = 0
                rolling = false
                art.load(parentID: parentID, fallbackItems: fallbackItems, type: type)
                start()
            } else {
                stop()
            }
        }
        .onDisappear(perform: stop)
    }

    // `key` forces a fresh ImageView identity per frame: ImageView holds its sources in @State, so
    // without a changing id it would freeze on the first image.
    private func frame(_ source: [ImageSource], key: Int) -> some View {
        ImageView(source)
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity) // fill the card, don't adopt the art's size
            .clipped()
            .overlay(Color.black.opacity(dim)) // dim so the foreground stays legible
            .id(key)
    }

    private func start() {
        stop()
        guard !reduceMotion else { return }
        cycle = Task { @MainActor in
            // Hold: show the tile as-is briefly so a quick focus pass doesn't flash.
            try? await Task.sleep(for: .seconds(Self.holdSeconds))
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.4)) { rolling = true }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.frameSeconds))
                if Task.isCancelled { return }
                let count = art.frames.count
                guard count > 1 else { continue }

                // Paint the new frame underneath (instant), cover it with the old frame on top, then
                // fade the old out → seamless dissolve, no black between.
                fadingIndex = index
                index = (index + 1) % count
                fadeOpacity = 1
                try? await Task.sleep(for: .milliseconds(20))
                if Task.isCancelled { return }
                withAnimation(.easeInOut(duration: Self.dissolveSeconds)) { fadeOpacity = 0 }
            }
        }
    }

    private func stop() {
        cycle?.cancel()
        cycle = nil
        rolling = false
        fadingIndex = nil
        fadeOpacity = 0
        art.stopPrefetch()
    }
}

// MARK: - BrunoArtCycleViewModel

//
// Loads a random sample of film art once (cached) and prefetches every frame so the cycle never gaps.
// Art is type-matched to the card: portrait posters for portrait tiles, landscape (Thumb/Backdrop)
// for landscape. Uses `fallbackItems` directly when `parentID` resolves to nothing (synthetic
// categories like Boxed Sets, whose group BoxSet has no real id).
@MainActor
final class BrunoArtCycleViewModel: ViewModel {

    @Published
    private(set) var frames: [[ImageSource]] = []

    private let prefetcher = BrunoPosterPrefetcher()
    private var warmed: [BaseItemDto] = []
    private var warmedType: PosterDisplayType = .portrait
    private var loaded = false

    func load(parentID: String?, fallbackItems: [BaseItemDto], type: PosterDisplayType) {
        guard !loaded, let userSession else { return }
        loaded = true
        warmedType = type
        let client = userSession.client
        let userID = userSession.user.id
        let width = BrunoShelfMetrics.posterMaxWidth(for: type)
        let quality = BrunoShelfMetrics.posterQuality
        Task {
            var items: [BaseItemDto] = []
            if let parentID, !parentID.isEmpty {
                var parameters = Paths.GetItemsParameters()
                parameters.userID = userID
                parameters.parentID = parentID
                parameters.includeItemTypes = [.movie]
                parameters.isRecursive = true
                parameters.sortBy = [ItemSortBy.random]
                parameters.limit = 10
                items = await (try? client.send(Paths.getItems(parameters: parameters)).value.items) ?? []
            }
            if items.isEmpty {
                items = Array(fallbackItems.shuffled().prefix(10))
            }
            let usable = items.filter { item in
                sources(for: item, type: type, width: width, quality: quality).contains { $0.url != nil }
            }
            warmed = usable
            frames = usable.map { sources(for: $0, type: type, width: width, quality: quality) }
            prefetcher.warm(usable, type: type)
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
