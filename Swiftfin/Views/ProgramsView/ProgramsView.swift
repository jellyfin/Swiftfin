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
// TODO: find other another way to handle channels/other views?

// Note: there are some unsafe first element accesses, but `ChannelProgram` data should always have a single program

struct ProgramsView: View {

    @EnvironmentObject
    private var mainRouter: MainCoordinator.Router
    @EnvironmentObject
    private var router: LiveTVCoordinator.Router

    @StateObject
    private var programsViewModel = ProgramsViewModel()

    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                programsViewModel.send(.refresh)
            }
    }

    @ViewBuilder
    private var liveTVSectionScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                liveTVSectionPill(
                    title: L10n.channels,
                    systemImage: "play.square.stack"
                ) {
                    router.route(to: \.channels)
                }
            }
            .edgePadding(.horizontal)
        }
    }

    // TODO: probably make own pill view
    //       - see if could merge with item view pills
    @ViewBuilder
    private func liveTVSectionPill(title: String, systemImage: String, onSelect: @escaping () -> Void) -> some View {
        Button {
            onSelect()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.callout.weight(.semibold))
                .foregroundColor(.primary)
                .padding(8)
                .background {
                    Color.systemFill
                        .cornerRadius(10)
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                liveTVSectionScrollView

                if programsViewModel.hasNoResults {
                    // TODO: probably change to "No Programs"
                    L10n.noResults.text
                }

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
        )
        .content {
            ProgramButtonContent(program: $0)
        }
        .imageOverlay {
            ProgramProgressOverlay(program: $0)
        }
        .onSelect {
            mainRouter.route(
                to: \.liveVideoPlayer,
                LiveVideoPlayerManager(program: $0)
            )
        }
    }

    var body: some View {
        WrappedView {
            switch programsViewModel.state {
            case .content:
                contentView
            case let .error(error):
                errorView(with: error)
            case .initial, .refreshing:
                DelayedProgressView()
            }
        }
        .navigationTitle(L10n.liveTV)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            if programsViewModel.state == .initial {
                programsViewModel.send(.refresh)
            }
        }
    }
}
