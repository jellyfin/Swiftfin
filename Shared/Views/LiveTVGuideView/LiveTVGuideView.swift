//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LiveTVGuideView: View {

    @Router
    private var router

    @StateObject
    private var channelsViewModel = PagingLibraryViewModel(library: GuideChannelsLibrary())
    @StateObject
    private var viewModel = GuideViewModel()

    var body: some View {
        ZStack {
            switch channelsViewModel.state {
            case .initial, .refreshing:
                ProgressView()
            case .content:
                if channelsViewModel.displayedElements.isEmpty {
                    ContentUnavailableView(L10n.noPrograms.localizedCapitalized, systemImage: "tv")
                } else {
                    contentView
                }
            case .error:
                channelsViewModel.error.map(ErrorView.init)
            }
        }
        .navigationTitle(L10n.guide)
        .topBarTrailing {
            GuideDateMenu(viewModel: viewModel)
        }
        .onFirstAppear {
            if channelsViewModel.state == .initial {
                channelsViewModel.refresh()
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .ignoresSafeArea(edges: .bottom)
        #else
        .ignoresSafeArea(edges: [.horizontal, .bottom])
        #endif
    }

    @ViewBuilder
    private var contentView: some View {
        LiveTVGuideContentView(
            viewModel: viewModel,
            channels: Array(channelsViewModel.displayedElements),
            onReachedBottomEdge: { channelsViewModel.getNextPage() },
            onSelectChannel: select,
            onSelectProgram: select
        )
    }

    private func select(_ item: BaseItemDto) {
        router.route(to: .item(item: item))
    }
}
