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

// struct ProgramsView: View {
//
//    @Router
//    private var router
//
//    @StateObject
//    private var programsViewModel = ProgramsViewModel()
//
//    private func errorView(with error: some Error) -> some View {
//        ErrorView(error: error)
//            .onRetry {
//                programsViewModel.send(.refresh)
//            }
//    }
//
//    @ViewBuilder
//    private var liveTVSectionScrollView: some View {
//        ScrollView(.horizontal, showsIndicators: false) {}
//    }
//
//    @ViewBuilder
//    private var contentView: some View {
//        ScrollView(showsIndicators: false) {
//            VStack(spacing: 20) {
//
//                liveTVSectionScrollView
//
//                if programsViewModel.hasNoResults {
//                    // TODO: probably change to "No Programs"
//                    Text(L10n.noResults)
//                }
//
//                if programsViewModel.recommended.isNotEmpty {
//                    programsSection(title: L10n.onNow, keyPath: \.recommended)
//                }
//
//                if programsViewModel.series.isNotEmpty {
//                    programsSection(title: L10n.series, keyPath: \.series)
//                }
//
//                if programsViewModel.movies.isNotEmpty {
//                    programsSection(title: L10n.movies, keyPath: \.movies)
//                }
//
//                if programsViewModel.kids.isNotEmpty {
//                    programsSection(title: L10n.kids, keyPath: \.kids)
//                }
//
//                if programsViewModel.sports.isNotEmpty {
//                    programsSection(title: L10n.sports, keyPath: \.sports)
//                }
//
//                if programsViewModel.news.isNotEmpty {
//                    programsSection(title: L10n.news, keyPath: \.news)
//                }
//            }
//        }
//    }
//
//    @ViewBuilder
//    private func programsSection(
//        title: String,
//        keyPath: KeyPath<ProgramsViewModel, [BaseItemDto]>
//    ) -> some View {
//        PosterHStack(
//            title: title,
//            elements: programsViewModel[keyPath: keyPath],
//            type: .landscape
//        ) { _, _ in
//            // router.route(
//            //     to: .liveVideoPlayer(manager: LiveVideoPlayerManager(program: item))
//            // )
//        }
////        } label: {
////            ProgramButtonContent(program: $0)
////        }
////        .posterOverlay(for: BaseItemDto.self) {
////            ProgramProgressOverlay(program: $0)
////        }
//    }
//
//    var body: some View {
//        ZStack {
//            switch programsViewModel.state {
//            case .content:
//                contentView
//            case let .error(error):
//                errorView(with: error)
//            case .initial, .refreshing:
//                DelayedProgressView()
//            }
//        }
//        .navigationTitle(L10n.liveTV)
//        .navigationBarTitleDisplayMode(.inline)
//        .onFirstAppear {
//            if programsViewModel.state == .initial {
//                programsViewModel.send(.refresh)
//            }
//        }
//    }
// }
