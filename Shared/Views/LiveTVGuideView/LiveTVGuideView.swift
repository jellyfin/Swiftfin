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

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Router
    private var router

    @StateObject
    private var channelsViewModel = PagingLibraryViewModel(library: GuideChannelsLibrary())
    @StateObject
    private var viewModel = GuideViewModel()

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

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
        .onFirstAppear {
            if channelsViewModel.state == .initial {
                channelsViewModel.refresh()
            }
        }
        #if os(iOS)
        .topBarTrailing {
            if isCompact {
                GuideDateMenu(viewModel: viewModel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        #else
        .ignoresSafeArea(edges: [.horizontal])
        #endif
    }

    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            if !isCompact {
                GuideDateBar(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
            }

            LiveTVGuideContentView(
                viewModel: viewModel,
                channels: Array(channelsViewModel.displayedElements),
                onReachedBottomEdge: {
                    channelsViewModel.getNextPage()
                },
                onSelectChannel: {
                    router.route(to: .item(item: $0))
                },
                onSelectProgram: {
                    router.route(to: .item(item: $0))
                }
            )
        }
    }
}
