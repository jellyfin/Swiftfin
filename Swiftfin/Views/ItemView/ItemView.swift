//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ItemView: View {

    @Default(.Customization.itemViewType)
    private var itemViewType

    @StateObject
    private var provider: ItemContentGroupProvider
    @StateObject
    private var viewModel: ContentGroupViewModel<ItemContentGroupProvider>

    init(provider: ItemContentGroupProvider) {
        self._provider = StateObject(wrappedValue: provider)
        self._viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
    }

    @ViewBuilder
    private var content: some View {
        if UIDevice.isPad {
            RegularEnhancedScrollView(provider: provider, viewModel: viewModel)
        } else {

            switch provider.item.type {
            case .movie, .series:
                switch itemViewType {
                case .enhanced where provider.item.backdropImageTags?.isNotEmpty == true:
                    CompactEnhancedScrollView(provider: provider, viewModel: viewModel)
                case .enhanced, .simple:
                    CompactSimpleScrollView(provider: provider, viewModel: viewModel)
                }
            case .person, .musicArtist:
                CompactPortraitScrollView(provider: provider, viewModel: viewModel)
            default:
                CompactSimpleScrollView(provider: provider, viewModel: viewModel)
            }
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                content
                    .navigationTitle(provider.item.displayTitle)
            case .error:
                viewModel.error.map(ErrorView.init)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .animation(.linear(duration: 0.1), value: viewModel.background.states)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.background.refresh()
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.refreshing),
            isHidden: !provider.item.showEditorMenu
        ) {
            ItemEditorMenu(item: provider.item)
        }
    }
}
