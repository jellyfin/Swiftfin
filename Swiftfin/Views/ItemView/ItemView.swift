//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
    @StoredValue(.User.enableItemEditing)
    private var enableItemEditing: Bool
    @StoredValue(.User.enableCollectionManagement)
    private var enableCollectionManagement: Bool

    private var canDelete: Bool {
        if viewModel.item.type == .boxSet {
            return enableCollectionManagement && viewModel.item.canDelete ?? false
        } else {
            return enableItemDeletion && viewModel.item.canDelete ?? false
        }
    }

    private var canEdit: Bool {
        if viewModel.item.type == .boxSet {
            return enableCollectionManagement
        } else {
            return enableItemEditing
        }
    }

    // Use to hide the menu button when not needed.
    // Add more checks as needed. For example, canDownload.
    private var enableMenu: Bool {
        canDelete || canEdit
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
        ZStack {
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
        .navigationBarMenuButton(
            isLoading: viewModel.backgroundStates.contains(.refresh),
            isHidden: !enableMenu
        ) {
            if canEdit {
                Button(L10n.edit, systemImage: "pencil") {
                    router.route(to: \.itemEditor, viewModel)
                }
            }

            if canDelete {
                Divider()
                Button(L10n.delete, systemImage: "trash", role: .destructive) {
                    showConfirmationDialog = true
                }
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
}
