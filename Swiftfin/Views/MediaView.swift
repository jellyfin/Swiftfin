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

struct MediaView: View {

    @EnvironmentObject
    private var router: MediaCoordinator.Router

    @ObservedObject
    var viewModel: MediaViewModel

    private var padLayout: CollectionVGridLayout {
        .minWidth(200)
    }

    private var phoneLayout: CollectionVGridLayout {
        .columns(2)
    }

    var body: some View {
        CollectionVGrid(
            $viewModel.libraries,
            layout: UIDevice.isPhone ? phoneLayout : padLayout
        ) { viewModel in
            MediaItem(viewModel: viewModel)
                .onSelect {
                    switch viewModel.item.collectionType {
                    case "downloads":
                        router.route(to: \.downloads)
                    case "favorites":
                        router.route(to: \.library, .init(parent: viewModel.item, filters: .favorites))
                    case "folders":
                        router.route(to: \.library, .init(parent: viewModel.item, filters: .init()))
                    case "livetv":
                        router.route(to: \.liveTV)
                    default:
                        router.route(to: \.library, .init(parent: viewModel.item, filters: .init()))
                    }
                }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .ignoresSafeArea()
        .navigationTitle(L10n.allMedia)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
        .onFirstAppear {
            Task {
                await viewModel.refresh()
            }
        }
    }
}

extension MediaView {

    struct MediaItem: View {

        @ObservedObject
        var viewModel: MediaItemViewModel

//        @State
//        private var imageSources: [ImageSource]

//        let item: BaseItemDto

        private var onSelect: () -> Void

        init(viewModel: MediaItemViewModel) {
//            self._imageSources = .init(initialValue: [])
//            self.item = item
            self.viewModel = viewModel
            self.onSelect = {}

//            if item.collectionType == "favorites" {
//                Task {
//                    try await getRandomItemImageSource(with: [.isFavorite])
//                }
//            } else if item.collectionType == "downloads" {
//                imageSources = []
//            } else if !Defaults[.Customization.Library.randomImage] || item.collectionType == "liveTV" {
//                imageSources = [item.imageSource(.primary, maxWidth: 500)]
//            } else {
//                Task {
//                    try await getRandomItemImageSource(with: nil)
//                }
//            }
        }

        var body: some View {
            Button {
                onSelect()
            } label: {
                ZStack {
                    Color.clear

                    ImageView(viewModel.imageSources)
                }
                .overlay {
                    if Defaults[.Customization.Library.randomImage] ||
                        viewModel.item.collectionType == "favorites" ||
                        viewModel.item.collectionType == "downloads"
                    {
                        ZStack {
                            Color.black
                                .opacity(0.5)

                            Text(viewModel.item.displayTitle)
                                .foregroundColor(.white)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .frame(alignment: .center)
                        }
                    }
                }
                .posterStyle(.landscape)
            }
        }
    }
}

extension MediaView.MediaItem {

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
