//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EPGView: View {

    @Router
    private var router

    @StateObject
    private var channelsViewModel = PagingLibraryViewModel(library: EPGChannelsLibrary())
    @StateObject
    private var viewModel = EPGViewModel()

    var body: some View {
        ZStack {
            switch (channelsViewModel.state, viewModel.state) {
            case (.initial, _), (.refreshing, _), (_, .initial), (_, .refreshing):
                ProgressView()
            case (.error, _):
                channelsViewModel.error.map {
                    ErrorView(error: $0)
                }
            case (_, .error):
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            case (.content, _):
                if channelsViewModel.displayedElements.isEmpty {
                    ContentUnavailableView(L10n.noPrograms.localizedCapitalized, systemImage: "tv")
                } else {
                    contentView
                }
            }
        }
        .onFirstAppear {
            if channelsViewModel.state == .initial {
                channelsViewModel.refresh()
            }
        }
        .backport
        .onChange(of: channelsViewModel.displayedElements) { _, channels in
            guard viewModel.state == .initial else { return }
            viewModel.refresh(channels: channels)
        }
        #if os(iOS)
        .topBarTrailing {
            EPGTypeMenu()

            EPGDateMenu(viewModel: viewModel)
        }
        .navigationTitle(L10n.guide)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        #else
        .ignoresSafeArea(edges: [.horizontal])
        #endif
    }

    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            #if os(tvOS)
            EPGDateBar(viewModel: viewModel)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            #endif

            EPGContentView(
                viewModel: viewModel,
                channelsViewModel: channelsViewModel
            ) {
                router.route(to: .item(item: $0))
            }
        }
    }
}
