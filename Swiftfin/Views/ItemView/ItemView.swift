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

    private func contentGroups(header: any ContentGroup) -> [any ContentGroup] {
        [header] + viewModel.groups
    }

    @ViewBuilder
    private var content: some View {
        CompactOrRegularView(isCompact: !UIDevice.isPad) {
            switch provider.item.type {
            case .movie, .series:
                switch itemViewType {
                case .enhanced where provider.item.backdropImageTags?.isNotEmpty == true:
                    BlurredNavigationBarScrollView(
                        groups: contentGroups(
                            header: CompactEnhancedHeaderContentGroup(provider: provider)
                        )
                    )
                case .enhanced, .simple:
                    ContentGroupScrollView(
                        groups: contentGroups(
                            header: CompactSimpleHeaderContentGroup(provider: provider)
                        )
                    )
                }
            case .person, .musicArtist:
                ContentGroupScrollView(
                    groups: contentGroups(
                        header: CompactPortraitHeaderContentGroup(provider: provider)
                    )
                )
            default:
                ContentGroupScrollView(
                    groups: contentGroups(
                        header: CompactSimpleHeaderContentGroup(provider: provider)
                    )
                )
            }
        } regularView: {
            switch itemViewType {
            case .enhanced where provider.item.type != .season:
                BlurredNavigationBarScrollView(
                    groups: contentGroups(
                        header: RegularEnhancedHeaderContentGroup(provider: provider)
                    )
                )
            case .enhanced, .simple:
                ContentGroupScrollView(
                    groups: contentGroups(
                        header: RegularSimpleHeaderContentGroup(provider: provider)
                    )
                )
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
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.refreshing),
            isHidden: !provider.item.canEdit
        ) {
            EditItemMenuContent(item: provider.item)
        }
    }
}
