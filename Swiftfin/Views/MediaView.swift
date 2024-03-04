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
                        let viewModel = ItemLibraryViewModel(parent: viewModel.item, filters: .favorites)
                        router.route(to: \.library, viewModel)
                    case "folders":
                        let viewModel = ItemLibraryViewModel(parent: viewModel.item, filters: .default)
                        router.route(to: \.library, viewModel)
                    case "livetv":
                        router.route(to: \.liveTV)
                    default:
                        let viewModel = ItemLibraryViewModel(parent: viewModel.item, filters: .default)
                        router.route(to: \.library, viewModel)
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
        private var viewModel: MediaItemViewModel

        private var onSelect: () -> Void

        init(viewModel: MediaItemViewModel) {
            self.viewModel = viewModel
            self.onSelect = {}
        }

        var body: some View {
            Button {
                onSelect()
            } label: {
                ZStack {
                    Color.clear

                    ImageView(viewModel.imageSources)
                        .id(viewModel.imageSources.hashValue)
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
