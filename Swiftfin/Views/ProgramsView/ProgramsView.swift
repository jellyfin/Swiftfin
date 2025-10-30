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

struct LiveTVGroupProvider: _ContentGroupProvider {

    let id: String = "live-tv"
    let displayTitle: String = L10n.liveTV
    let systemImage: String = "heart.fill"

    @ArrayBuilder<any _ContentGroup>
    func makeGroups(environment: ()) async throws -> [any _ContentGroup] {
        LiveTVChannelsPillGroup()

        PosterGroup(
            id: "programs-recommended",
            library: RecommendedProgramsLibrary(),
            posterDisplayType: .landscape,
            posterSize: .small
        )

        [
            ProgramSection.series,
            .movies,
            .kids,
            .sports,
            .news,
        ]
            .map { section in
                PosterGroup(
                    id: "programs-\(section.rawValue)",
                    library: ProgramsLibrary(section: section),
                    posterDisplayType: .landscape,
                    posterSize: .small
                )
            }
    }
}

struct LiveTVChannelsPillGroup: _ContentGroup {

    let id: String = "asdf"
    let displayTitle: String = ""

    @ViewBuilder
    func body(with viewModel: VoidContentGroupViewModel) -> some View {
        _Body()
    }

    private struct _Body: View {

        @Router
        private var router

        var body: some View {
            ScrollView(.horizontal) {
                HStack {
                    Button {
                        router.route(to: .channels)
                    } label: {
                        Label(
                            L10n.channels,
                            systemImage: "play.square.stack"
                        )
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background {
                            Color.systemFill
                                .cornerRadius(10)
                        }
                    }
                }
                .edgePadding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }
}
