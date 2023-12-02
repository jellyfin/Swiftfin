//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import CollectionView
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
        ) { library in
            LibraryCard(item: library)
                .onSelect {
                    switch library.collectionType {
                    case "downloads":
                        router.route(to: \.downloads)
                    case "favorites":
                        router.route(to: \.library, .init(parent: library, type: .library, filters: .favorites))
                    case "folders":
                        router.route(to: \.library, .init(parent: library, type: .folders, filters: .init()))
                    case "liveTV":
                        router.route(to: \.liveTV)
                    default:
                        router.route(to: \.library, .init(parent: library, type: .library, filters: .init()))
                    }
                }
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

        @State
        private var imageSources: [ImageSource]

        let item: BaseItemDto
        private var onSelect: () -> Void

        init(item: BaseItemDto) {
            self._imageSources = .init(initialValue: [])
            self.item = item
            self.onSelect = {}

            if item.collectionType == "favorites" {
                getRandomItemImageSource(with: [.isFavorite])
            } else if item.collectionType == "downloads" {
                imageSources = []
            } else if !Defaults[.Customization.Library.randomImage] || item.collectionType == "liveTV" {
                imageSources = [item.imageSource(.primary, maxWidth: 500)]
            } else {
                getRandomItemImageSource(with: nil)
            }
        }

        private func getRandomItemImageSource(with filters: [ItemFilter]?) {
            Task {

                let userSession = Container.userSession.callAsFunction()

                let parameters = Paths.GetItemsParameters(
                    userID: userSession.user.id,
                    limit: 1,
                    isRecursive: true,
                    parentID: item.id,
                    includeItemTypes: [.movie, .series],
                    filters: filters,
                    sortBy: ["Random"]
                )
                let request = Paths.getItems(parameters: parameters)
                let response = try await userSession.client.send(request)

                guard let item = response.value.items?.first else { return }

                await MainActor.run {
                    imageSources = [item.imageSource(.backdrop, maxWidth: 500)]
                }
            }
        }

        var body: some View {
            Button {
                onSelect()
            } label: {
                ImageView(imageSources)
                    .overlay {
                        if Defaults[.Customization.Library.randomImage] ||
                            item.collectionType == "favorites" ||
                            item.collectionType == "downloads"
                        {
                            ZStack {
                                Color.black
                                    .opacity(0.5)

                                Text(item.displayTitle)
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

extension MediaView.LibraryCard {

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
