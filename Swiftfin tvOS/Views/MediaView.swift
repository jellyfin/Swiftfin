//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import Stinsen
import SwiftUI

struct MediaView: View {

    @EnvironmentObject
    private var mainRouter: MainCoordinator.Router
    @EnvironmentObject
    private var router: MediaCoordinator.Router

    @StateObject
    private var viewModel = MediaViewModel()

    private var contentView: some View {
        CollectionVGrid(
            $viewModel.mediaItems,
            layout: .columns(4, insets: .init(50), itemSpacing: 50, lineSpacing: 50)
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
                    case .downloads: ()
                    case .favorites:
                        let viewModel = ItemLibraryViewModel(
                            title: L10n.favorites,
                            filters: .favorites
                        )
                        router.route(to: \.library, viewModel)
                    case .liveTV:
                        mainRouter.root(\.liveTV)
                    }
                }
        }
    }

    var body: some View {
        WrappedView {
            Group {
                switch viewModel.state {
                case .content:
                    contentView
                case let .error(error):
                    Text(error.localizedDescription)
                case .initial, .refreshing:
                    ProgressView()
                }
            }
            .transition(.opacity.animation(.linear(duration: 0.2)))
        }
        .ignoresSafeArea()
        .onFirstAppear {
            viewModel.send(.refresh)
        }
    }
}

extension MediaView {

    // TODO: custom view for folders and tv (allow customization?)
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
            .buttonStyle(.card)
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
