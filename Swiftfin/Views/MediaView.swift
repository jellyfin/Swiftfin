//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import JellyfinAPI
import Stinsen
import SwiftUI

struct MediaView: View {

    @EnvironmentObject
    private var router: MediaCoordinator.Router

    @ObservedObject
    var viewModel: MediaViewModel

    private var gridLayout: NSCollectionLayoutSection.GridLayoutMode {
        if UIDevice.isPhone {
            return .fixedNumberOfColumns(2)
        } else {
            return .adaptive(withMinItemSize: PosterType.landscape.width)
        }
    }

    var body: some View {
        CollectionView(items: viewModel.libraryItems) { _, viewModel, _ in
            LibraryCard(viewModel: viewModel)
                .onSelect {
                    switch viewModel.item.collectionType {
                    case "downloads":
                        router.route(to: \.downloads)
                    case "favorites":
                        router.route(to: \.library, .init(parent: viewModel.item, type: .library, filters: .favorites))
                    case "folders":
                        router.route(to: \.library, .init(parent: viewModel.item, type: .folders, filters: .init()))
                    case "liveTV":
                        router.route(to: \.liveTV)
                    default:
                        router.route(to: \.library, .init(parent: viewModel.item, type: .library, filters: .init()))
                    }
                }
        }
        .layout { _, layoutEnvironment in
            .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: gridLayout,
                sectionInsets: .init(top: 0, leading: 10, bottom: 0, trailing: 10)
            )
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
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
    }
}

extension MediaView {

    struct LibraryCard: View {

        @ObservedObject
        var viewModel: MediaItemViewModel

        private var onSelect: () -> Void

        private var itemWidth: CGFloat {
            PosterType.landscape.width * (UIDevice.isPhone ? 0.85 : 1)
        }

        var body: some View {
            Button {
                onSelect()
            } label: {
                Group {
                    if let imageSources = viewModel.imageSources {
                        ImageView(imageSources)
                    } else {
                        ImageView(nil)
                    }
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
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(alignment: .center)
                        }
                    }
                }
                .posterStyle(type: .landscape, width: itemWidth)
            }
        }
    }
}

extension MediaView.LibraryCard {

    init(viewModel: MediaItemViewModel) {
        self.init(
            viewModel: viewModel,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
