//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import JellyfinAPI
import SwiftUI

struct RemoteImageSearchView: View {

    @ObservedObject
    private var viewModel: ItemImageViewModel

    @Router
    private var router

    @StateObject
    private var remoteImageInfoViewModel: RemoteImageInfoViewModel

    private var imageType: ImageType {
        remoteImageInfoViewModel.remoteImageLibrary.library.imageType
    }

    private var layout: CollectionVGridLayout {
        guard UIDevice.isPhone else {
            return .minWidth(150)
        }

        return posterType == .landscape ? .columns(2) : .columns(3)
    }

    private var posterType: PosterDisplayType {
        imageType.posterDisplayType(for: viewModel.item.type)
    }

    init(viewModel: ItemImageViewModel, imageType: ImageType) {
        self.viewModel = viewModel
        self._remoteImageInfoViewModel = StateObject(
            wrappedValue: .init(
                itemID: viewModel.item.id ?? "unknown",
                imageType: imageType
            )
        )
    }

    var body: some View {
        ImageElementsView(
            viewModel: remoteImageInfoViewModel.remoteImageLibrary,
            itemImageViewModel: viewModel,
            layout: layout,
            posterType: posterType
        )
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(imageType.displayTitle.localizedCapitalized)
        .navigationBarBackButtonHidden(viewModel.background.is(.updating))
        .navigationBarMenuButton(isLoading: viewModel.background.is(.updating)) {
            ImageProvidersMenuContent(viewModel: remoteImageInfoViewModel)
        }
        .navigationBarCloseButton {
            router.dismiss()
        }
        .onFirstAppear {
            remoteImageInfoViewModel.refresh()
        }
        .refreshable {
            remoteImageInfoViewModel.refresh()
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                router.dismiss()
            case .deleted:
                break
            }
        }
    }
}

extension RemoteImageSearchView {

    private struct ImageElementsView: View {

        @ObservedObject
        private var viewModel: PagingLibraryViewModel<RemoteImageLibrary>

        @Router
        private var router

        private let itemImageViewModel: ItemImageViewModel
        private let layout: CollectionVGridLayout
        private let posterType: PosterDisplayType

        init(
            viewModel: PagingLibraryViewModel<RemoteImageLibrary>,
            itemImageViewModel: ItemImageViewModel,
            layout: CollectionVGridLayout,
            posterType: PosterDisplayType
        ) {
            self.viewModel = viewModel
            self.itemImageViewModel = itemImageViewModel
            self.layout = layout
            self.posterType = posterType
        }

        @ViewBuilder
        private var gridView: some View {
            if viewModel.elements.isEmpty {
                ContentUnavailableView(
                    L10n.noResults.localizedCapitalized,
                    systemImage: "photo"
                )
            } else {
                CollectionVGrid(
                    uniqueElements: viewModel.elements,
                    layout: layout
                ) { image in
                    imageButton(image)
                }
                .onReachedBottomEdge(offset: .offset(300)) {
                    viewModel.getNextPage()
                }
            }
        }

        @ViewBuilder
        private func imageButton(_ image: RemoteImageInfo) -> some View {
            PosterButton(
                item: image,
                type: posterType
            ) { namespace in
                router.route(
                    to: .remoteImageDetail(
                        viewModel: itemImageViewModel,
                        remoteImageInfo: image
                    ), in: namespace
                )
            } label: {
                EmptyView()
            }
        }

        var body: some View {
            ZStack {
                switch viewModel.state {
                case .content:
                    gridView
                case .initial, .refreshing:
                    ProgressView()
                case .error:
                    viewModel.error.map(ErrorView.init)
                }
            }
            .animation(.linear(duration: 0.1), value: viewModel.state)
        }
    }

    private struct ImageProvidersMenuContent: View {

        @ObservedObject
        private var remoteImagesViewModel: PagingLibraryViewModel<RemoteImageLibrary>
        @ObservedObject
        private var providersViewModel: PagingLibraryViewModel<RemoteImageProvidersLibrary>

        init(viewModel: RemoteImageInfoViewModel) {
            self.remoteImagesViewModel = viewModel.remoteImageLibrary
            self.providersViewModel = viewModel.remoteImageProvidersLibrary
        }

        var body: some View {
            Group {
                Toggle(
                    L10n.allLanguages,
                    isOn: $remoteImagesViewModel.environment.includeAllLanguages
                )

                if providersViewModel.elements.isNotEmpty {
                    Picker(selection: $remoteImagesViewModel.environment.provider) {
                        Text(L10n.all)
                            .tag(nil as String?)

                        ForEach(providersViewModel.elements) { provider in
                            Text(provider.name ?? L10n.unknown)
                                .tag(provider.name)
                        }
                    } label: {
                        Text(L10n.provider)
                        Text(remoteImagesViewModel.environment.provider ?? L10n.all)
                    }
                    .pickerStyle(.menu)
                }
            }
            .backport
            .onChange(of: remoteImagesViewModel.environment) {
                remoteImagesViewModel.refresh()
            }
        }
    }
}
