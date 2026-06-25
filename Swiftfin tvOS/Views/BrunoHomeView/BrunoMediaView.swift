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

// MARK: - BrunoMediaView (tvOS only)

//
// The Movies / TV Shows tabs, branded to match Home & Collections: a cinematic spotlight hero for
// the category (a few high-rated, backdrop-having titles that auto-advance) atop a full A–Z poster
// grid. Hero + grid share ONE scroll plane (like Home), so the hero scrolls away as you browse and
// vertical focus traverses hero <-> grid with no special handling.
struct BrunoMediaView: View {

    let itemType: BaseItemKind
    let heroEyebrow: String

    @StateObject
    private var viewModel: BrunoMediaViewModel

    @State
    private var spotlightIndex = 0

    @Router
    private var router

    init(itemType: BaseItemKind, heroEyebrow: String) {
        self.itemType = itemType
        self.heroEyebrow = heroEyebrow
        _viewModel = StateObject(wrappedValue: BrunoMediaViewModel(itemType: itemType))
    }

    var body: some View {
        ZStack {
            // One fixed ambient backdrop (the first spotlight) — keeps the surface snappy by never
            // re-blurring as the hero rotates or you scroll (Home's pattern).
            BrunoAmbientBackground(item: viewModel.heroItems.first)

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .tint(Color.bruno.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .onFirstAppear {
            Task { await viewModel.load() }
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 36) {
                if viewModel.heroItems.isNotEmpty {
                    BrunoHeroView(
                        items: viewModel.heroItems,
                        index: $spotlightIndex,
                        eyebrow: heroEyebrow,
                        bleedsTop: true,
                        extraHeight: 160
                    )
                }

                BrunoPosterGrid(items: viewModel.items) { item in
                    router.route(to: .item(item: item))
                }
            }
            .padding(.bottom, 60)
        }
    }
}

// MARK: - BrunoPosterGrid

//
// The shared full poster grid for Bruno's category surfaces (Movies / TV / Kids): a lazy 7-up
// portrait grid that mirrors the home/collections shelf cells (stock PosterButton + title).
struct BrunoPosterGrid: View {

    let items: [BaseItemDto]
    let onItem: (BaseItemDto) -> Void

    // 7 portrait posters per row, matching the home/collections shelves.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 30), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 40) {
            ForEach(items, id: \.id) { item in
                PosterButton(item: item, type: .portrait) {
                    onItem(item)
                } label: {
                    PosterButton<BaseItemDto>.TitleSubtitleContentView(item: item)
                }
            }
        }
        .padding(.horizontal, 50)
    }
}

// MARK: - BrunoMediaViewModel

@MainActor
final class BrunoMediaViewModel: ViewModel {

    @Published
    private(set) var items: [BaseItemDto] = []
    @Published
    private(set) var heroItems: [BaseItemDto] = []
    @Published
    private(set) var isLoading = true

    private let itemType: BaseItemKind

    init(itemType: BaseItemKind) {
        self.itemType = itemType
        super.init()
    }

    func load() async {
        guard let userSession else {
            isLoading = false
            return
        }

        var parameters = Paths.GetItemsParameters()
        parameters.userID = userSession.user.id
        parameters.isRecursive = true
        parameters.includeItemTypes = [itemType]
        parameters.sortBy = [.sortName]
        parameters.sortOrder = [.ascending]
        // Overview + genres feed the hero's meta line; the rest (backdrop tags, community rating,
        // user data for the poster overlays) come back by default.
        parameters.fields = [.overview, .genres]
        parameters.enableUserData = true
        parameters.limit = 1000

        do {
            let all = try await userSession.client.send(Paths.getItems(parameters: parameters)).value.items ?? []
            items = all

            // Spotlight pool: the highest-rated titles that actually have a backdrop, in a fresh
            // random order so re-entry varies (mirrors the home hero).
            let candidates = all
                .filter { $0.backdropImageTags?.isNotEmpty == true }
                .sorted { ($0.communityRating ?? 0) > ($1.communityRating ?? 0) }
            heroItems = Array(
                BrunoRNG.shuffled(Array(candidates.prefix(30)), seed: UInt32.random(in: 1 ... UInt32.max)).prefix(5)
            )
        } catch {
            // Leave items/heroItems empty; the grid simply shows nothing rather than trapping.
        }

        isLoading = false
    }
}
