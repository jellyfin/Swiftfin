//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: Add scrollTargetLayout and scrollTargetBehavior to the scroll views.
// TODO: isCompact determination by available width

struct ItemView: View {

    enum Component {
        static let header = "itemView-header"
        static let menu = "itemView-menu"
        static let play = "itemView-play"
    }

    @Default(.Customization.itemViewType)
    private var itemViewType

    @Router
    private var router

    private var buttonConfiguration = ItemActionButtons.Configuration()

    @State
    private var contentSize: CGSize = .zero

    @StateObject
    private var focusCoordinator = FocusCoordinator(initial: Component.play)
    @StateObject
    private var provider: ItemContentGroupProvider
    @StateObject
    private var viewModel: ContentGroupViewModel<ItemContentGroupProvider>
    @StateObject
    private var deleteViewModel: ItemEditorViewModel

    init(provider: ItemContentGroupProvider) {
        self._provider = StateObject(wrappedValue: provider)
        self._viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
        self._deleteViewModel = StateObject(wrappedValue: ItemEditorViewModel(item: provider.item))
    }

    private var isCompact: Bool {
        contentSize.width < 600
    }

    private var isEnhanced: Bool {
        switch itemViewType {
        case .enhanced:
            guard provider.item.backdropImageTags?.isNotEmpty == true else {
                return false
            }

            if isCompact {
                return provider.item.type == .movie
                    || provider.item.type == .series
                    || provider.item.type == .program
                    || provider.item.type == .liveTvProgram
            }

            return provider.item.type != .person && provider.item.type != .season
        case .simple:
            return false
        }
    }

    private var contentGroups: [any ContentGroup] {
        let header: any ContentGroup = switch (isEnhanced, isCompact) {
        case (true, true):
            CompactEnhancedHeaderContentGroup(provider: provider)
        case (true, false):
            RegularEnhancedHeaderContentGroup(provider: provider)
        case (false, true):
            CompactSimpleHeaderContentGroup(provider: provider)
        case (false, false):
            RegularSimpleHeaderContentGroup(provider: provider)
        }

        return [header] + viewModel.groups
    }

    @ViewBuilder
    private func contentGroupScrollView(
        isEnhanced: Bool = false
    ) -> some View {
        ContentGroupScrollView(
            provider: provider,
            groups: contentGroups,
            isEnhanced: isEnhanced
        )
    }

    @ViewBuilder
    private var blurredNavigationBarScrollView: some View {
        BlurredNavigationBarScrollView(groups: contentGroups)
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch (isEnhanced, isCompact) {
            case (true, true):
                blurredNavigationBarScrollView
            case (true, false):
                InlinePlatformView {
                    blurredNavigationBarScrollView
                } tvOSView: {
                    contentGroupScrollView(isEnhanced: true)
                }
            default:
                contentGroupScrollView()
            }
        }
        .navigationTitle(provider.item.displayTitle)
    }

    var body: some View {
        let (_, overflow, menu) = buttonConfiguration.resolvedButtons(for: provider)

        ZStack {
            switch viewModel.state {
            case .content:
                content
            case .error:
                viewModel.error.map(ErrorView.init)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .trackingSize($contentSize)
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.2), value: viewModel.background.states)
        .toolbarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.background.refresh()
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .environmentObject(focusCoordinator)
        .confirmationDialog(
            L10n.deleteItemConfirmationMessage,
            isPresented: $provider.isPresentingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                L10n.confirm,
                role: .destructive,
                action: deleteViewModel.delete
            )

            Button(L10n.cancel, role: .cancel) {}
        }
        .onNotification(.didDeleteItem) { itemID in
            guard itemID == provider.item.id else { return }

            UIDevice.feedback(.success)
            router.dismiss()
        }
        .errorMessage($deleteViewModel.error)
        #if os(tvOS)
            .toolbarVisibility(.hidden, for: .navigationBar)
        #else
            .navigationBarMenuButton(
                isLoading: viewModel.background.is(.refreshing),
                isHidden: overflow.isEmpty && menu.isEmpty
            ) {
                ItemActionButtons.MenuContent(
                    provider: provider,
                    buttons: overflow,
                    menuButtons: menu
                )
            }
        #endif
    }
}
