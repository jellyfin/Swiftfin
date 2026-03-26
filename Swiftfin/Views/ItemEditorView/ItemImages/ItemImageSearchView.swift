//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import CollectionVGrid
import JellyfinAPI
import SwiftUI

struct ItemImageSearchView: View {

    @Router
    private var router

    @ObservedObject
    private var viewModel: ItemImageViewModel

    @StateObject
    private var remoteImageInfoViewModel: RemoteImageInfoViewModel

    private var layout: CollectionVGridLayout {
        posterType == .landscape ? .minWidth(150) : .minWidth(100)
    }

    private var posterType: PosterDisplayType {
        remoteImageInfoViewModel.imageType.posterDisplayType(for: viewModel.item.type)
    }

    init(viewModel: ItemImageViewModel, imageType: ImageType) {
        self.viewModel = viewModel
        self._remoteImageInfoViewModel = StateObject(
            wrappedValue: RemoteImageInfoViewModel(
                imageType: imageType,
                parent: viewModel.item
            )
        )
    }

    var body: some View {
        ZStack {
            switch remoteImageInfoViewModel.state {
            case .initial, .refreshing:
                ProgressView()
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(remoteImageInfoViewModel.imageType.displayTitle)
        .animation(.linear(duration: 0.1), value: remoteImageInfoViewModel.state)
        .navigationBarBackButtonHidden(viewModel.background.is(.updating))
        .navigationBarMenuButton(isLoading: viewModel.background.is(.updating)) {
            Button {
                remoteImageInfoViewModel.includeAllLanguages.toggle()
            } label: {
                if remoteImageInfoViewModel.includeAllLanguages {
                    Label(L10n.allLanguages, systemImage: "checkmark")
                } else {
                    Text(L10n.allLanguages)
                }
            }

            if remoteImageInfoViewModel.providers.isNotEmpty {
                Menu {
                    Button {
                        remoteImageInfoViewModel.provider = nil
                    } label: {
                        if remoteImageInfoViewModel.provider == nil {
                            Label(L10n.all, systemImage: "checkmark")
                        } else {
                            Text(L10n.all)
                        }
                    }

                    ForEach(remoteImageInfoViewModel.providers, id: \.self) { provider in
                        Button {
                            remoteImageInfoViewModel.provider = provider
                        } label: {
                            if remoteImageInfoViewModel.provider == provider {
                                Label(provider, systemImage: "checkmark")
                            } else {
                                Text(provider)
                            }
                        }
                    }
                } label: {
                    Text(L10n.provider)
                    Text(remoteImageInfoViewModel.provider ?? L10n.all)
                }
            }
        }
        .onFirstAppear {
            remoteImageInfoViewModel.send(.refresh)
        }
        .refreshable {
            remoteImageInfoViewModel.send(.refresh)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            case .deleted:
                break
            }
        }
        .errorMessage($viewModel.error)
    }

    @ViewBuilder
    private var contentView: some View {
        if remoteImageInfoViewModel.elements.isEmpty {
            ContentUnavailableView(
                L10n.noResults.localizedCapitalized,
                systemImage: "photo"
            )
        } else {
            CollectionVGrid(
                uniqueElements: remoteImageInfoViewModel.elements,
                layout: layout
            ) { image in
                Button {
                    viewModel.remoteImageInfo = image
                    router.route(
                        to: .itemImageDetails(
                            viewModel: viewModel,
                            imageDetail: image
                        )
                    )
                } label: {
                    PosterImage(
                        item: image,
                        type: posterType
                    )
                }
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                remoteImageInfoViewModel.send(.getNextPage)
            }
        }
    }
}
