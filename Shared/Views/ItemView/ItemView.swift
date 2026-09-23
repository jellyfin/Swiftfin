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

struct ItemView: View {

    enum Component {

        static let header = "itemView-header"
        static let menu = "itemView-menu"
        static let play = "itemView-play"
    }

    @Default(.Customization.itemViewType)
    private var itemViewType

    @AdaptiveLayout
    private var viewLayout

    @Environment(\.frameForParentView)
    private var frameForParentView

    @Router
    private var router

    private var buttonConfiguration = ItemActionButtons.Configuration()

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
        viewLayout.usesCompactDetail
    }

    private var usesCompactEnhancedHeader: Bool {
        // The sidebar changes the space for controls, not the artwork's layout.
        // Include the sidebar's inset so opening it doesn't replace the header.
        guard !viewLayout.isLarge,
              let navigation = frameForParentView[.navigationStack],
              navigation.frame.width > 0
        else { return isCompact }

        return viewLayout.resolving(size: navigation.sizeIncludingSafeArea).usesCompactDetail
    }

    private var isEnhanced: Bool {
        switch itemViewType {
        case .enhanced:
            guard provider.item.backdropImageTags?.isNotEmpty == true else {
                return false
            }

            if usesCompactEnhancedHeader {
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
        let header: any ContentGroup = switch (isEnhanced, isEnhanced ? usesCompactEnhancedHeader : isCompact) {
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
    private var content: some View {
        if isEnhanced, !viewLayout.isLarge {
            BlurredNavigationBarScrollView(groups: contentGroups)
        } else {
            ContentGroupScrollView(
                provider: provider,
                groups: contentGroups,
                isEnhanced: isEnhanced
            )
        }
    }

    var body: some View {
        let (_, overflow, menu) = buttonConfiguration.resolvedButtons(for: provider)

        GeometryReader { proxy in
            let safeArea = frameForParentView[.navigationStack]?.safeAreaInsets ?? proxy.safeAreaInsets
            let horizontalInsets = EdgeInsets(
                top: 0,
                leading: viewLayout.isLarge ? 0 : safeArea.leading,
                bottom: 0,
                trailing: viewLayout.isLarge ? 0 : safeArea.trailing
            )

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
            .layoutContainer(size: CGSize(
                width: max(0, proxy.size.width - horizontalInsets.leading - horizontalInsets.trailing),
                height: proxy.size.height
            ))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(horizontalInsets)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .animation(
                viewLayout.isLarge ? nil : .smooth(duration: 0.35),
                value: horizontalInsets
            )
        }
        // The native tab sidebar changes the safe area immediately. Animate our
        // own horizontal insets inside a stable container to slide the content.
        .ignoresSafeArea(.container, edges: viewLayout.isLarge ? [] : .horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.2), value: viewModel.background.states)
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(provider.item.displayTitle)
        .refreshable {
            await viewModel.background.refresh()
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
        .onChange(of: provider.$item.value == nil) { _, isUnavailable in
            if isUnavailable {
                router.dismiss()
            }
        }
        .errorMessage($deleteViewModel.error)
        .errorMessage($provider.actionError)
        #if os(tvOS)
        .toolbarVisibility(.hidden, for: .navigationBar)
        #else
        .toolbarBackground(isEnhanced ? .hidden : .automatic, for: .navigationBar)
        .toolbar {
            if isEnhanced {
                ToolbarItem(placement: .principal) {
                    // Keep the title for back navigation without drawing it over the artwork.
                    Color.clear.frame(width: 0, height: 0)
                }
            }
        }
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
