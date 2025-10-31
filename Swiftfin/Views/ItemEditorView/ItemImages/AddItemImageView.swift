//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import CollectionVGrid
import JellyfinAPI
import SwiftUI

// TODO: different layouts per image type
//       - also based on iOS vs iPadOS

struct AddItemImageView: View {

    @ObservedObject
    private var itemImagesViewModel: ItemImagesViewModel

    @Router
    private var router

    @State
    private var error: Error?

    @StateObject
    private var remoteImageInfoViewModel: RemoteImageInfoViewModel

    init(viewModel: ItemImagesViewModel, imageType: ImageType) {
        self.itemImagesViewModel = viewModel
        self._remoteImageInfoViewModel = StateObject(
            wrappedValue: .init(
                itemID: viewModel.item.id ?? "unknown",
                imageType: imageType
            )
        )
    }

    var body: some View {
        ZStack {
            ImageElementsView(
                viewModel: remoteImageInfoViewModel.remoteImageLibrary,
                itemImagesViewModel: itemImagesViewModel,
                remoteImageInfoViewModel: remoteImageInfoViewModel
            )
        }
        .navigationTitle(remoteImageInfoViewModel.remoteImageLibrary.library.imageType.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(itemImagesViewModel.backgroundStates.contains(.updating))
        .navigationBarMenuButton(isLoading: itemImagesViewModel.backgroundStates.contains(.updating)) {
            ImageProvidersMenuContent(
                viewModel: remoteImageInfoViewModel
            )
        }
        .onFirstAppear {
            remoteImageInfoViewModel.refresh()
        }
        .onReceive(itemImagesViewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            case let .error(eventError):
                UIDevice.feedback(.error)
                error = eventError
            }
        }
        .errorMessage($error)
    }
}

extension AddItemImageView {

    struct ImageElementsView: View {

        @ObservedObject
        private var viewModel: PagingLibraryViewModel<RemoteImageLibrary>

        @Router
        private var router

        private let itemImagesViewModel: ItemImagesViewModel
        private let layout: CollectionVGridLayout = .minWidth(150)
        private let remoteImageInfoViewModel: RemoteImageInfoViewModel

        init(
            viewModel: PagingLibraryViewModel<RemoteImageLibrary>,
            itemImagesViewModel: ItemImagesViewModel,
            remoteImageInfoViewModel: RemoteImageInfoViewModel
        ) {
            self.viewModel = viewModel
            self.itemImagesViewModel = itemImagesViewModel
            self.remoteImageInfoViewModel = remoteImageInfoViewModel
        }

        @ViewBuilder
        private var gridView: some View {
            if viewModel.elements.isEmpty {
                Text(L10n.none)
            } else {
                CollectionVGrid(
                    uniqueElements: viewModel.elements,
                    layout: layout,
                    viewProvider: imageButton
                )
                .onReachedBottomEdge(offset: .offset(300)) {
                    viewModel.retrieveNextPage()
                }
            }
        }

        @ViewBuilder
        private func imageButton(_ image: RemoteImageInfo) -> some View {
            Button {
                router.route(
                    to: .itemSearchImageDetails(
                        viewModel: itemImagesViewModel,
                        remoteImageInfo: image
                    )
                )
            } label: {
                PosterImage(
                    item: image,
                    type: image.preferredPosterDisplayType
                )
                .pipeline(.Swiftfin.other)
            }
        }

        @ViewBuilder
        private func errorView(with error: some Error) -> some View {
            ErrorView(error: error)
                .onRetry {
                    remoteImageInfoViewModel.refresh()
                }
        }

        var body: some View {
            ZStack {
                switch viewModel.state {
                case .content:
                    gridView
                case .initial, .refreshing:
                    DelayedProgressView()
                case .error:
                    viewModel.error.map { errorView(with: $0) }
                }
            }
            .animation(.linear(duration: 0.1), value: viewModel.state)
        }
    }

    struct ImageProvidersMenuContent: View {

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

                        ForEach(
                            providersViewModel.elements,
                        ) { provider in
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
            .onChange(of: remoteImagesViewModel.environment) { _, _ in
                remoteImagesViewModel.refresh()
            }
        }
    }
}
