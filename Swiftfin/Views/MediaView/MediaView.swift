//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Factory
import JellyfinAPI

import SwiftUI

// TODO: seems to redraw view when popped to sometimes?
//       - similar to HomeView TODO bug?
// TODO: list view
// TODO: `afterLastDisappear` with `backgroundRefresh`
struct MediaView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = MediaViewModel()

    @Injected(\.networkMonitor)
    private var networkMonitor

    @EnvironmentObject
    private var rootCoordinator: RootCoordinator

    private var padLayout: CollectionVGridLayout {
        .minWidth(200)
    }

    private var phoneLayout: CollectionVGridLayout {
        .columns(2)
    }

    @ViewBuilder
    private var contentView: some View {
        CollectionVGrid(
            uniqueElements: viewModel.mediaItems,
            layout: UIDevice.isPhone ? phoneLayout : padLayout
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
                    router.route(to: .downloads)
                case .favorites:
                    // TODO: favorites should have its own view instead of a library
                    let viewModel = ItemLibraryViewModel(
                        title: L10n.favorites,
                        id: "favorites",
                        filters: .favorites
                    )
                    router.route(to: .library(viewModel: viewModel), in: namespace)
                case .liveTV:
                    router.route(to: .liveTV)
                }
            }
        }
    }

    private func errorView(with error: some Error) -> some View {
        VStack(spacing: 20) {
            ErrorView(error: error)
                .onRetry {
                    viewModel.send(.refresh)
                }

            if !networkMonitor.isConnected {
                Button {
                    rootCoordinator.root(.downloads)
                } label: {
                    Label("View Downloads", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: 300)
            }
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                errorView(with: error)
            case .initial, .refreshing:
                DelayedProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea()
        .navigationTitle(L10n.allMedia)
        .topBarTrailing {
            if viewModel.state == .refreshing {
                ProgressView()
            }
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
    }
}
