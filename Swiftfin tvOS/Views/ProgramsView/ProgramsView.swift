//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: background refresh for programs with timer?

// Note: there are some unsafe first element accesses, but `ChannelProgram` data should always have a single program

struct ProgramsView: View {

    @Router
    private var router

    @StateObject
    private var programsViewModel = ProgramsViewModel()

    @ViewBuilder
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if programsViewModel.recommended.isNotEmpty {
                    programsSection(title: L10n.onNow, keyPath: \.recommended)
                }

                if programsViewModel.series.isNotEmpty {
                    programsSection(title: L10n.series, keyPath: \.series)
                }

                if programsViewModel.movies.isNotEmpty {
                    programsSection(title: L10n.movies, keyPath: \.movies)
                }

                if programsViewModel.kids.isNotEmpty {
                    programsSection(title: L10n.kids, keyPath: \.kids)
                }

                if programsViewModel.sports.isNotEmpty {
                    programsSection(title: L10n.sports, keyPath: \.sports)
                }

                if programsViewModel.news.isNotEmpty {
                    programsSection(title: L10n.news, keyPath: \.news)
                }
            }
        }
    }

    @ViewBuilder
    private func programsSection(
        title: String,
        keyPath: KeyPath<ProgramsViewModel, [BaseItemDto]>
    ) -> some View {
        PosterHStack(
            title: title,
            type: .landscape,
            items: programsViewModel[keyPath: keyPath]
        ) { _ in
//            guard let mediaSource = channelProgram.channel.mediaSources?.first else { return }
//            router.route(
//                to: \.liveVideoPlayer,
//                LiveVideoPlayerManager(item: channelProgram.channel, mediaSource: mediaSource)
//            )
        } label: {
            ProgramButtonContent(program: $0)
        }
        .posterOverlay(for: BaseItemDto.self) {
            ProgramProgressOverlay(program: $0)
        }
    }

    var body: some View {
        ZStack {
            switch programsViewModel.state {
            case .content:
                if programsViewModel.hasNoResults {
                    Text(L10n.noResults)
                } else {
                    contentView
                }
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: programsViewModel.state)
        .ignoresSafeArea(edges: [.bottom, .horizontal])
        .refreshable {
            programsViewModel.send(.refresh)
        }
        .onFirstAppear {
            if programsViewModel.state == .initial {
                programsViewModel.send(.refresh)
            }
        }
    }
}
