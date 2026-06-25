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
// logo / director headshot) for a contained carousel of the collection's movie posters, advancing
// every 2s and cross-fading; on unfocus it reverts to the static art. Mirrors PosterButton's button
// structure (PosterImage isn't injectable, so we rebuild the thin shell) so focus scale / shadow /
// zoom-push behave identically — only the image content differs.
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
// The card's image area. Reads the enclosing card's focus via `\.isFocused` (true when the card is
// focused). On focus it lazily loads the collection's movie posters and runs a 2s cross-fade cycle;
// only the focused card has a live cycle task (started on focus, cancelled on unfocus/disappear),
// honoring the "one timer at a time" rule. Respects Reduce Motion (shows the first poster, no auto-
// advance).
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
    @State
    private var cycle: Task<Void, Never>?

    /// Show posters only once focused AND some have loaded — otherwise the static art stays put.
    private var active: Bool {
        isFocused && !children.sources.isEmpty
    }

    var body: some View {
        ZStack {
            // Dark backing so a contained (letterboxed) poster sits on the card surface, not on void.
            Color.bruno.surface

            PosterImage(item: item, type: type)
                .opacity(active ? 0 : 1)

            if active, let source = children.sources[safe: index] {
                ImageView(source)
                    .aspectRatio(contentMode: .fit)
                    .id(source.url?.hashValue)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: reduceMotion ? 0 : 0.35), value: index)
        .animation(.easeInOut(duration: reduceMotion ? 0 : 0.3), value: active)
        .onChange(of: isFocused) { _, focused in
            if focused {
                children.load(parentID: item.id ?? "")
                index = 0
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
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                if Task.isCancelled { return }
                let count = children.sources.count
                guard count > 1 else { continue }
                index = (index + 1) % count
            }
        }
    }

    private func stopCycle() {
        cycle?.cancel()
        cycle = nil
    }
}

// MARK: - BrunoChildArtViewModel

//
// Loads a collection's child-movie poster sources once (cached), on first focus. Random order so the
// carousel varies between visits. Studios/Directors are box sets of movies — same fetch as
// BrunoBoxSetYearRangesViewModel, but keeping primary posters instead of years.
@MainActor
final class BrunoChildArtViewModel: ViewModel {

    @Published
    private(set) var sources: [ImageSource] = []

    private var loaded = false

    func load(parentID: String) {
        guard !loaded, !parentID.isEmpty, let userSession else { return }
        loaded = true
        let client = userSession.client
        let userID = userSession.user.id
        Task {
            var parameters = Paths.GetItemsParameters()
            parameters.userID = userID
            parameters.parentID = parentID
            parameters.includeItemTypes = [.movie]
            parameters.isRecursive = true
            parameters.sortBy = [ItemSortBy.random]
            parameters.limit = 20
            do {
                let items = try await client.send(Paths.getItems(parameters: parameters)).value.items ?? []
                sources = items
                    .map { $0.imageSource(.primary, maxWidth: 300) }
                    .filter { $0.url != nil }
            } catch {}
        }
    }
}
