//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: scrollTargetLayout and scrollTargetBehavior to scroll views

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

    private var isEnhanced: Bool {
        switch itemViewType {
        case .enhanced:
            provider.item.type != .person && provider.item.type != .season
        case .simple:
            false
        }
    }

    private var header: any ContentGroup {
        if isEnhanced {
            return EnhancedRegularHeaderContentGroup(provider: provider)
        }

        return RegularSimpleHeaderContentGroup(provider: provider)
    }

    private var content: some View {
        ContentGroupScrollView(
            provider: provider,
            groups: contentGroups(header: header),
            isEnhanced: isEnhanced
        )
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
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.2), value: viewModel.background.states)
        .onFirstAppear {
            viewModel.refresh()
        }
        .refreshable {
            viewModel.refresh()
        }
    }
}
