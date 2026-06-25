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
// sample of films under `parentID`) behind a persistent foreground (a title, logo, …); at rest it
// shows just `background`. Built to be dropped on any focusable surface — the group tiles here, and
// the per-card carousels / other systems later.
//
// Perf-safe by construction (mirrors the in-card carousel rules):
//   • Reads the enclosing focusable's focus via `\.isFocused` — ONLY the focused tile cycles.
//   • A 2s HOLD after focus shows the card as-is first, so a quick pass-through doesn't flash.
//   • Frames are prefetched into the Nuke memory cache (BrunoPosterPrefetcher, same pipeline + width
//     as the cells), so each swap reads from cache — no transitional gap. Capped to the warm window.
//   • The cycle task is started on focus and cancelled on unfocus/disappear; Reduce Motion holds the
//     static background (no auto-advance).
struct BrunoFocusArtCycle<Background: View, Foreground: View>: View {

    private let parentID: String?
    private let dim: Double
    private let background: () -> Background
    private let foreground: () -> Foreground

    init(
        parentID: String?,
        dim: Double = 0.55,
        @ViewBuilder background: @escaping () -> Background,
        @ViewBuilder foreground: @escaping () -> Foreground
    ) {
        self.parentID = parentID
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
    @State
    private var rolling = false
    @State
    private var cycle: Task<Void, Never>?

    private static var holdSeconds: Double {
        2
    }

    private static var frameSeconds: Double {
        2
    }

    private var active: Bool {
        rolling && !art.frames.isEmpty
    }

    var body: some View {
        ZStack {
            background()

            if active, let frame = art.frames[safe: index] {
                ImageView(frame)
                    .aspectRatio(contentMode: .fill)
                    .id(index)
                    .transition(.opacity)
                    .overlay(Color.black.opacity(dim)) // dim so the foreground stays legible
            }

            foreground()
        }
        .clipped()
        .animation(.easeInOut(duration: reduceMotion ? 0 : 0.4), value: index)
        .animation(.easeInOut(duration: reduceMotion ? 0 : 0.3), value: active)
        .onChange(of: isFocused) { _, focused in
            if focused {
                index = 0
                rolling = false
                art.load(parentID: parentID)
                start()
            } else {
                stop()
            }
        }
        .onDisappear(perform: stop)
    }

    private func start() {
        stop()
        guard !reduceMotion else { return }
        cycle = Task { @MainActor in
            try? await Task.sleep(for: .seconds(Self.holdSeconds))
            if Task.isCancelled { return }
            rolling = true
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.frameSeconds))
                if Task.isCancelled { return }
                let count = art.frames.count
                guard count > 1 else { continue }
                index = (index + 1) % count
            }
        }
    }

    private func stop() {
        cycle?.cancel()
        cycle = nil
        rolling = false
        art.stopPrefetch()
    }
}

// MARK: - BrunoArtCycleViewModel

//
// Loads a random sample of landscape film art under `parentID` once (cached), and prefetches every
// frame so the cycle never gaps. Landscape (Thumb/Backdrop) reads as ambient art behind a title.
@MainActor
final class BrunoArtCycleViewModel: ViewModel {

    @Published
    private(set) var frames: [[ImageSource]] = []

    private let prefetcher = BrunoPosterPrefetcher()
    private var warmed: [BaseItemDto] = []
    private var loaded = false

    func load(parentID: String?) {
        guard !loaded, let parentID, let userSession else { return }
        loaded = true
        let client = userSession.client
        let userID = userSession.user.id
        let width = BrunoShelfMetrics.posterMaxWidth(for: .landscape)
        let quality = BrunoShelfMetrics.posterQuality
        Task {
            var parameters = Paths.GetItemsParameters()
            parameters.userID = userID
            parameters.parentID = parentID
            parameters.includeItemTypes = [.movie]
            parameters.isRecursive = true
            parameters.sortBy = [ItemSortBy.random]
            parameters.limit = 10
            do {
                let items = try await client.send(Paths.getItems(parameters: parameters)).value.items ?? []
                let usable = items.filter { item in
                    item.landscapeImageSources(maxWidth: width, quality: quality).contains { $0.url != nil }
                }
                warmed = usable
                frames = usable.map { $0.landscapeImageSources(maxWidth: width, quality: quality) }
                prefetcher.warm(usable, type: .landscape)
            } catch {}
        }
    }

    func stopPrefetch() {
        prefetcher.stop(warmed, type: .landscape)
    }
}
