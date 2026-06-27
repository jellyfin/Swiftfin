//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Engine
import Factory
import JellyfinAPI
import SwiftUI

struct MediaView: View {

    @Router
    private var router

    #if os(tvOS)
    // Shared, session-scoped instance (see Container.mediaViewModel) — already warmed by the launch
    // prefetch in HomeView, so the tab opens with its tile backdrops already loaded.
    @InjectedObject(\.mediaViewModel)
    private var viewModel

    // Used both to detect LEAVING the Media tab (to pre-roll backdrops) and to jump the Live TV tile
    // straight to the Live TV (guide) tab.
    @EnvironmentObject
    private var tabCoordinator: TabCoordinator
    #else
    @StateObject
    private var viewModel = MediaViewModel()
    #endif

    private var layout: CollectionVGridLayout {
        if UIDevice.isTV {
            .columns(4, insets: .init(50), itemSpacing: 50, lineSpacing: 50)
        } else if UIDevice.isPad {
            .minWidth(200)
        } else {
            .columns(2)
        }
    }

    @ViewBuilder
    private var content: some View {
        CollectionVGrid(
            uniqueElements: viewModel.mediaItems,
            layout: layout
        ) { mediaType in
            MediaItem(viewModel: viewModel, type: mediaType) { namespace in
                switch mediaType {
                case let .collectionFolder(item):
                    let viewModel = ItemLibraryViewModel(
                        parent: item,
                        filters: .default
                    )
                    router.route(to: .library(viewModel: viewModel), in: namespace)
                case .downloads:
                    router.route(to: .downloadList)
                case .favorites:
                    #if os(tvOS)
                    // A collection-style detail page: rows for Movies, TV Shows, Actors (favorited).
                    router.route(
                        to: .mediaCollection(
                            title: L10n.favorites,
                            id: "favorites",
                            itemTypes: [.movie, .series, .person],
                            traits: [.isFavorite]
                        ),
                        in: namespace
                    )
                    #else
                    // TODO: favorites should have its own view instead of a library
                    let viewModel = ItemLibraryViewModel(
                        title: L10n.favorites,
                        id: "favorites",
                        filters: .favorites
                    )
                    router.route(to: .library(viewModel: viewModel), in: namespace)
                    #endif
                case .watchlist:
                    #if os(tvOS)
                    // The KefinTweaks watchlist is the Jellyfin `Likes` flag. Same collection-style page.
                    router.route(
                        to: .mediaCollection(
                            title: "Watchlist",
                            id: "watchlist",
                            // No Actors row — you can't "watchlist" a person (only Favorites can).
                            itemTypes: [.movie, .series],
                            traits: [.likes]
                        ),
                        in: namespace
                    )
                    #else
                    let viewModel = ItemLibraryViewModel(
                        title: "Watchlist",
                        id: "watchlist",
                        filters: .init(traits: [.likes])
                    )
                    router.route(to: .library(viewModel: viewModel), in: namespace)
                    #endif
                case .liveTV:
                    #if os(tvOS)
                    // Go straight to the existing Live TV GUIDE (the Live TV tab's EPG), rather than
                    // pushing the separate programs page. Selecting the tab reuses the guide as-is.
                    tabCoordinator.selectedTabID = "liveTV"
                    #else
                    router.route(to: .liveTV)
                    #endif
                }
            }
        }
    }

    var body: some View {
        ZStack {
            Color.clear

            switch viewModel.state {
            case .initial:
                content
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            case .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea()
        .navigationTitle(L10n.allMedia.localizedCapitalized)
        .refreshable {
            viewModel.refresh()
        }
        .onFirstAppear {
            #if os(tvOS)
            // Safety net: the launch prefetch usually fills the tiles before the user gets here. If it
            // hasn't yet (cold open straight to Media), prepare them now.
            if viewModel.tileImageSources.isEmpty {
                Task { await viewModel.prepareTileImages(reloadList: true) }
            }
            #else
            viewModel.refresh()
            #endif
        }
        #if os(tvOS)
        // Re-roll the random backdrops the MOMENT the user LEAVES the Media tab (selection changes away
        // from "media"). tvOS keeps the off-screen tab alive, so the new wallpapers fetch + prefetch in
        // the background and are already in place when the user returns — no visible swap on arrival.
        .backport
            .onChange(of: tabCoordinator.selectedTabID) { oldID, newID in
                // Re-roll ONLY on the single transition AWAY from Media (old == "media", new != "media").
                // Browsing among other tabs afterward must NOT keep re-rolling — the backdrops resolved on
                // that exit are exactly what shows on return, untouched until the user comes back and
                // leaves again.
                if oldID == "media", newID != "media" {
                    Task { await viewModel.prepareTileImages(reloadList: false) }
                }
            }
        #endif
            .if(UIDevice.isTV) { view in
                    view.toolbar(.hidden, for: .navigationBar)
                }
    }
}
