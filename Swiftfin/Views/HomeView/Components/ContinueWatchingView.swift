//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import SwiftUI

extension HomeView {

    struct ContinueWatchingView: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: HomeViewModel

        // TODO: see how this looks across multiple screen sizes
        //       alongside PosterHStack + landscape
        // TODO: need better handling for iPadOS + portrait orientation
        private var columnCount: CGFloat {
            if UIDevice.isPhone {
                1.5
            } else {
                3.5
            }
        }

        @ViewBuilder
        private func posterLabel(
            for item: BaseItemDto
        ) -> some View {
            if item.type == .episode {
                VStack(alignment: .leading, spacing: 0) {
                    if item.showTitle, let seriesName = item.seriesName {
                        Text(seriesName)
                            .font(.footnote)
                            .fontWeight(.regular)
                            .foregroundColor(.primary)
                            .lineLimit(1, reservesSpace: true)
                    }

                    DotHStack(padding: 3) {
                        Text(item.seasonEpisodeLabel ?? .emptyDash)

                        if item.showTitle {
                            Text(item.displayTitle)
                        } else if let seriesName = item.seriesName {
                            Text(seriesName)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }
            } else {
                TitleSubtitleContentView(
                    title: item.displayTitle,
                    subtitle: item.subtitle
                )
            }
        }

        var body: some View {
            EmptyView()
//            PosterHStack(
//                title: "Continue Watching",
//                type: .landscape,
//                items: viewModel.resumeItems
//            ) { item, namespace in
//                router.route(to: .item(item: item), in: namespace)
//            }
//            .contextMenu(for: BaseItemDto.self) { item in
//                Button {
//                    viewModel.send(.setIsPlayed(true, item))
//                } label: {
//                    Label(L10n.played, systemImage: "checkmark.circle")
//                }
//
//                Button(role: .destructive) {
//                    viewModel.send(.setIsPlayed(false, item))
//                } label: {
//                    Label(L10n.unplayed, systemImage: "minus.circle")
//                }
//            }
//            .posterStyle(for: BaseItemDto.self) { value, item in
//                var value = value
            ////                value.displayType = .landscape
//                value.label = posterLabel(for: item)
//                    .eraseToAnyView()
            ////                value.overlay = LandscapePosterProgressBar(
            ////                    title: item.progressLabel ?? L10n.continue,
            ////                    progress: (item.userData?.playedPercentage ?? 0) / 100
            ////                )
//                if let progress = item.progress, let startSeconds = item.startSeconds {
//                    value.overlay = PosterProgressBar(
//                        title: startSeconds.formatted(.runtime),
//                        progress: progress,
//                        posterDisplayType: value.displayType
//                    )
//                    .eraseToAnyView()
//                }
//
//                value.size = .medium
//
//                return value
//            }
        }
    }
}
