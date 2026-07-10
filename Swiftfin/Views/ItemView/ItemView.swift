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

    protocol ScrollContainerView: View {

        associatedtype Content: View

        init(provider: ItemContentGroupProvider, content: @escaping () -> Content)
    }

    @Default(.Customization.itemViewType)
    private var itemViewType

    @Router
    private var router

    @StateObject
    private var provider: ItemContentGroupProvider

    @StateObject
    private var viewModel: ContentGroupViewModel<ItemContentGroupProvider>

    init(provider: ItemContentGroupProvider) {
        self._provider = StateObject(wrappedValue: provider)
        self._viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
    }

    // TODO: break out into pad vs phone views based on item type
    private func scrollContainerView(
        provider: ItemContentGroupProvider,
        content: @escaping () -> some View
    ) -> any ScrollContainerView {

        if UIDevice.isPad {
            return iPadOSCinematicScrollView(provider: provider, content: content)
        }

        switch provider.item.type {
        case .movie, .series:
            switch itemViewType {
            case .enhanced where provider.item.backdropImageTags?.isNotEmpty == true:
                return CinematicScrollView(provider: provider, content: content)
            case .enhanced, .simple:
                return SimpleScrollView(provider: provider, content: content)
            }
        case .person, .musicArtist:
            return CompactPosterScrollView(provider: provider, content: content)
        default:
            return SimpleScrollView(provider: provider, content: content)
        }
    }

    @ViewBuilder
    private var innerBody: some View {
        scrollContainerView(provider: provider) {
            ContentGroupVStack(groups: viewModel.groups)
        }
        .eraseToAnyView()
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                innerBody
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
            viewModel.refresh()
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
