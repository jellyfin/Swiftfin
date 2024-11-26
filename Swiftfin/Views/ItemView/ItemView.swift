//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: try to make views simpler so there isn't one per media type, but per view type
//       - basic (episodes, collection) vs more fancy (rest)
//       - think about future for other media types

struct ItemView: View {

    @EnvironmentObject
    private var router: ItemCoordinator.Router

    @StateObject
    private var viewModel: ItemViewModel
    @StateObject
    private var deleteViewModel: DeleteItemViewModel

    @State
    private var showConfirmationDialog = false
    @State
    private var isPresentingEventAlert = false
    @State
    private var error: JellyfinAPIError?

    @StoredValue(.User.enableItemDeletion)
    private var enableItemDeletion: Bool
    @StoredValue(.User.enableItemEditor)
    private var enableItemEditor: Bool

    private var canDelete: Bool {
        enableItemDeletion && viewModel.item.canDelete ?? false
    }

    // As more menu items exist, this can either be expanded to include more validation or removed if there are permanent menu items.
    private var enableMenu: Bool {
        canDelete || enableItemEditor
    }

    private static func typeViewModel(for item: BaseItemDto) -> ItemViewModel {
        switch item.type {
        case .boxSet:
            return CollectionItemViewModel(item: item)
        case .episode:
            return EpisodeItemViewModel(item: item)
        case .movie:
            return MovieItemViewModel(item: item)
        case .series:
            return SeriesItemViewModel(item: item)
        default:
            assertionFailure("Unsupported item")
            return ItemViewModel(item: item)
        }
    }

    init(item: BaseItemDto) {
        self._viewModel = StateObject(wrappedValue: Self.typeViewModel(for: item))
        self._deleteViewModel = StateObject(wrappedValue: DeleteItemViewModel(item: item))
    }

    @ViewBuilder
    private var padView: some View {
        switch viewModel.item.type {
        case .boxSet:
            iPadOSCollectionItemView(viewModel: viewModel as! CollectionItemViewModel)
        case .episode:
            iPadOSEpisodeItemView(viewModel: viewModel as! EpisodeItemViewModel)
        case .movie:
            iPadOSMovieItemView(viewModel: viewModel as! MovieItemViewModel)
        case .series:
            iPadOSSeriesItemView(viewModel: viewModel as! SeriesItemViewModel)
        default:
            Text(L10n.notImplementedYetWithType(viewModel.item.type ?? "--"))
        }
    }

    @ViewBuilder
    private var phoneView: some View {
        switch viewModel.item.type {
        case .boxSet:
            CollectionItemView(viewModel: viewModel as! CollectionItemViewModel)
        case .episode:
            EpisodeItemView(viewModel: viewModel as! EpisodeItemViewModel)
        case .movie:
            MovieItemView(viewModel: viewModel as! MovieItemViewModel)
        case .series:
            SeriesItemView(viewModel: viewModel as! SeriesItemViewModel)
        default:
            Text(L10n.notImplementedYetWithType(viewModel.item.type ?? "--"))
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if UIDevice.isPad {
            padView
        } else {
            phoneView
        }
    }

    var body: some View {
        WrappedView {
            switch viewModel.state {
            case .content:
                contentView
                    .navigationTitle(viewModel.item.displayTitle)
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                DelayedProgressView()
            }
        }
        .transition(.opacity.animation(.linear(duration: 0.2)))
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.refresh) {
                ProgressView()
            }
            if enableMenu {
                itemActionMenu
            }
        }
        .confirmationDialog(
            L10n.deleteItemConfirmationMessage,
            isPresented: $showConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button(L10n.confirm, role: .destructive) {
                deleteViewModel.send(.delete)
            }
            Button(L10n.cancel, role: .cancel) {}
        }
        .onReceive(deleteViewModel.events) { event in
            switch event {
            case let .error(eventError):
                error = eventError
                isPresentingEventAlert = true
            case .deleted:
                router.dismissCoordinator()
            }
        }
        .alert(
            L10n.error,
            isPresented: $isPresentingEventAlert,
            presenting: error
        ) { _ in
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    @ViewBuilder
    private var itemActionMenu: some View {

        Menu(L10n.options, systemImage: "ellipsis.circle") {

            if enableItemEditor {
                Button(L10n.edit, systemImage: "pencil") {
                    router.route(to: \.itemEditor, viewModel.item)
                }
            }

            if canDelete {
                Divider()
                Button(L10n.delete, systemImage: "trash", role: .destructive) {
                    showConfirmationDialog = true
                }
            }
        }
        .labelStyle(.iconOnly)
        .backport
        .fontWeight(.semibold)
    }
}
