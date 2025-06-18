//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ItemView: View {

    protocol ScrollContainerView: View {

        associatedtype Content: View

        init(viewModel: ItemViewModel, content: @escaping () -> Content)
    }

    @Default(.Customization.itemViewType)
    private var itemViewType

    @EnvironmentObject
    private var router: ItemCoordinator.Router

    @StateObject
    private var viewModel: ItemViewModel
    @StateObject
    private var deleteViewModel: DeleteItemViewModel

    @State
    private var isPresentingConfirmationDialog = false
    @State
    private var isPresentingEventAlert = false
    @State
    private var error: JellyfinAPIError?

    // MARK: - Can Delete Item

    private var canDelete: Bool {
        viewModel.userSession.user.permissions.items.canDelete(item: viewModel.item)
    }

    // MARK: - Can Edit Item

    private var canEdit: Bool {
        viewModel.userSession.user.permissions.items.canEditMetadata(item: viewModel.item)
        // TODO: Enable when Subtitle / Lyric Editing is added
        // || viewModel.userSession.user.permissions.items.canManageLyrics(item: viewModel.item)
        // || viewModel.userSession.user.permissions.items.canManageSubtitles(item: viewModel.item)
    }

    // MARK: - Deletion or Editing is Enabled

    private var enableMenu: Bool {
        canEdit || canDelete
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
    private var scrollContentView: some View {
        switch viewModel.item.type {
        case .boxSet:
            CollectionItemContentView(viewModel: viewModel as! CollectionItemViewModel)
        case .episode:
            EpisodeItemContentView(viewModel: viewModel as! EpisodeItemViewModel)
        case .movie:
            MovieItemContentView(viewModel: viewModel as! MovieItemViewModel)
        case .series:
            SeriesItemContentView(viewModel: viewModel as! SeriesItemViewModel)
        default:
            Text(L10n.notImplementedYetWithType(viewModel.item.type ?? "--"))
        }
    }

    // TODO: break out into pad vs phone views based on item type
    private func scrollContainerView<Content: View>(
        viewModel: ItemViewModel,
        content: @escaping () -> Content
    ) -> any ScrollContainerView {

        if UIDevice.isPad {
            return iPadOSCinematicScrollView(viewModel: viewModel, content: content)
        }

        if viewModel.item.type == .movie || viewModel.item.type == .series {
            switch itemViewType {
            case .compactPoster:
                return CompactPosterScrollView(viewModel: viewModel, content: content)
            case .compactLogo:
                return CompactLogoScrollView(viewModel: viewModel, content: content)
            case .cinematic:
                return CinematicScrollView(viewModel: viewModel, content: content)
            }
        }

        return SimpleScrollView(viewModel: viewModel, content: content)
    }

    @ViewBuilder
    private var innerBody: some View {
        scrollContainerView(viewModel: viewModel) {
            scrollContentView
        }
        .eraseToAnyView()
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                innerBody
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
                Section {
                    Button(L10n.delete, systemImage: "trash", role: .destructive) {
                        isPresentingConfirmationDialog = true
                    }
                }
            }
        }
        .confirmationDialog(
            L10n.deleteItemConfirmationMessage,
            isPresented: $isPresentingConfirmationDialog,
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
