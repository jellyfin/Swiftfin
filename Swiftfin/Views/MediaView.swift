//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Factory
import JellyfinAPI
import Stinsen
import SwiftUI

// TODO: seems to redraw view when popped to sometimes?
//       - similar to HomeView TODO bug?
// TODO: list view
struct MediaView: View {

    @EnvironmentObject
    private var router: MediaCoordinator.Router

    @StateObject
    private var viewModel = MediaViewModel()

    private var padLayout: CollectionVGridLayout {
        .minWidth(200)
    }

    private var phoneLayout: CollectionVGridLayout {
        .columns(2)
    }

    private var contentView: some View {
        CollectionVGrid(
            $viewModel.mediaItems,
            layout: UIDevice.isPhone ? phoneLayout : padLayout
        ) { mediaType in
            MediaItem(viewModel: viewModel, type: mediaType)
                .onSelect {
                    switch mediaType {
                    case let .collectionFolder(item):
                        let viewModel = ItemLibraryViewModel(
                            parent: item,
                            filters: .default
                        )
                        router.route(to: \.library, viewModel)
                    case .downloads:
                        router.route(to: \.downloads)
                    case .favorites:
                        let viewModel = ItemLibraryViewModel(
                            title: L10n.favorites,
                            filters: .favorites
                        )
                        router.route(to: \.library, viewModel)
                    case .liveTV:
                        router.route(to: \.liveTV)
                    }
                }
        }
    }

    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.refresh)
            }
    }

    var body: some View {
        WrappedView {
            Group {
                switch viewModel.state {
                case .content:
                    contentView
                case let .error(error):
                    errorView(with: error)
                case .initial, .refreshing:
                    ProgressView()
                }
            }
            .transition(.opacity.animation(.linear(duration: 0.1)))
        }
        .ignoresSafeArea()
        .navigationTitle(L10n.allMedia)
        .topBarTrailing {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
    }
}

extension MediaView {

    // TODO: custom view for folders and tv (allow customization?)
    //       - differentiate between what media types are Swiftfin only
    //         which would allow some cleanup
    //       - allow server or random view per library?
    struct MediaItem: View {

        @Default(.Customization.Library.randomImage)
        private var useRandomImage

        @ObservedObject
        var viewModel: MediaViewModel

        @State
        private var imageSources: [ImageSource] = []

        private var onSelect: () -> Void
        private let mediaType: MediaViewModel.MediaType

        init(viewModel: MediaViewModel, type: MediaViewModel.MediaType) {
            self.viewModel = viewModel
            self.onSelect = {}
            self.mediaType = type
        }

        private func setImageSources() {
            Task { @MainActor in
                if useRandomImage {
                    self.imageSources = try await viewModel.randomItemImageSources(for: mediaType)
                    return
                }

                if case let MediaViewModel.MediaType.collectionFolder(item) = mediaType {
                    self.imageSources = [item.imageSource(.primary, maxWidth: 500)]
                } else if case let MediaViewModel.MediaType.liveTV(item) = mediaType {
                    self.imageSources = [item.imageSource(.primary, maxWidth: 500)]
                }
            }
        }

        private var titleLabel: some View {
            Text(mediaType.displayTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(alignment: .center)
        }

        var body: some View {
            Button {
                onSelect()
            } label: {
                ZStack {
                    Color.clear

                    ImageView(imageSources)
                        .image { image in
                            if useRandomImage ||
                                mediaType == .downloads ||
                                mediaType == .favorites
                            {
                                ZStack {
                                    image

                                    Color.black
                                        .opacity(0.5)

                                    titleLabel
                                        .foregroundStyle(.white)
                                }
                            } else {
                                image
                            }
                        }
                        .failure {
                            ImageView.DefaultFailureView()
                                .overlay {
                                    titleLabel
                                        .foregroundColor(.primary)
                                }
                        }
                        .id(imageSources.hashValue)
                }
                .posterStyle(.landscape)
            }
            .onFirstAppear(perform: setImageSources)
            .onChange(of: useRandomImage) { _ in
                setImageSources()
            }
        }
    }
}

extension MediaView.MediaItem {

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
