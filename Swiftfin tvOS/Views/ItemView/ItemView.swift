//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ItemView: View {

    @StateObject
    private var provider: ItemContentGroupProvider
    @StateObject
    private var viewModel: ContentGroupViewModel<ItemContentGroupProvider>

    init(provider: ItemContentGroupProvider) {
        self._provider = StateObject(wrappedValue: provider)
        self._viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
    }

    private var groups: [any ContentGroup] {
        [HeaderContentGroup(provider: provider)] + viewModel.groups
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                RegularEnhancedScrollView(
                    provider: provider,
                    groups: groups
                )
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
