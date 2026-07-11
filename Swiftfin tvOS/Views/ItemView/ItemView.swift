//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ItemView: View {

    protocol ScrollContainerView: View {

        associatedtype Content: View

        init(provider: ItemContentGroupProvider, content: @escaping () -> Content)
    }

    @StateObject
    private var provider: ItemContentGroupProvider

    @StateObject
    private var viewModel: ContentGroupViewModel<ItemContentGroupProvider>

    init(provider: ItemContentGroupProvider) {
        self._provider = StateObject(wrappedValue: provider)
        self._viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
    }

    // MARK: scrollContainerView

    private func scrollContainerView(
        provider: ItemContentGroupProvider,
        content: @escaping () -> some View
    ) -> any ScrollContainerView {
        RegularEnhancedScrollView(provider: provider, content: content)
    }

    private var contentGroups: [any ContentGroup] {
        [HeaderContentGroup(provider: provider)] + viewModel.groups
    }

    @ViewBuilder
    private var innerBody: some View {
        scrollContainerView(provider: provider) {
            ContentGroupVStack(groups: contentGroups)
        }
        .eraseToAnyView()
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                innerBody
            case .error:
                viewModel.error.map(ErrorView.init)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .animation(.linear(duration: 0.1), value: viewModel.background.states)
        .onFirstAppear {
            viewModel.refresh()
        }
        .refreshable {
            viewModel.refresh()
        }
    }
}
