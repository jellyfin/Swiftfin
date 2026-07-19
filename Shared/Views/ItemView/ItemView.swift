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

    @Default(.Customization.itemViewType)
    private var itemViewType

    @State
    private var contentSize: CGSize = .zero

    @StateObject
    private var provider: ItemContentGroupProvider
    @StateObject
    private var viewModel: ContentGroupViewModel<ItemContentGroupProvider>

    init(provider: ItemContentGroupProvider) {
        self._provider = StateObject(wrappedValue: provider)
        self._viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
    }

    private var isCompact: Bool {
        contentSize.width < 600
    }

    private var isEnhanced: Bool {
        switch itemViewType {
        case .enhanced:

            if provider.item.type != .audio || provider.item.type != .musicAlbum {
                return false
            }

            if provider.item.backdropImageTags?.isEmpty == true {
                return false
            }

            if isCompact {
                return provider.item.type == .movie || provider.item.type == .series
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
        .backport
        .toolbarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.background.refresh()
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        #if os(tvOS)
        .toolbarVisibility(.hidden, for: .navigationBar)
        #else
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.refreshing),
            isHidden: !provider.item.canEdit
        ) {
            EditItemMenuContent(item: provider.item)
        }
        #endif
    }
}
