//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import JellyfinAPI
import SwiftUI

struct SeriesEpisodeSelector: View {

    @EnvironmentObject
    private var mainRouter: MainCoordinator.Router

    @ObservedObject
    var viewModel: SeriesItemViewModel

    @State
    private var selection: BaseItemDto?

    var body: some View {
        Text("")
    }

//    @ViewBuilder
//    private var selectorMenu: some View {
//        Menu {
//            ForEach(viewModel.seasons, id: \.hashValue) { seasonViewModel in
//                Button {
//                    selection = seasonViewModel
//                } label: {
//                    if seasonViewModel == selection {
//                        Label(seasonViewModel.season.displayTitle, systemImage: "checkmark")
//                    } else {
//                        Text(seasonViewModel.season.displayTitle)
//                    }
//                }
//            }
//        } label: {
//            Label(
//                selection?.season.displayTitle ?? .emptyDash,
//                systemImage: "chevron.down"
//            )
//            .font(.title3.weight(.semibold))
//        }
//        .padding(.bottom)
//        .fixedSize()
//    }
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            selectorMenu
//                .edgePadding(.horizontal)
//
//            if let selection {
//                TestView(viewModel: selection)
//            }
//        }
//        .onChange(of: viewModel.seasons) { newValue in
//            selection = newValue.first
//        }
//        .onChange(of: selection) { newValue in
//            guard let newValue else { return }
//
//            if newValue.state == .initial {
//                newValue.send(.refresh)
//            }
//        }
//    }
}

struct TestView: View {

    @ObservedObject
    var viewModel: SeasonItemViewModel

    var body: some View {
        CollectionHStack(
            $viewModel.elements,
            columns: UIDevice.isPhone ? 1.5 : 3.5
        ) { episode in
            PosterButton(
                item: episode,
                type: .landscape,
                singleImage: true
            )
            .content {
                SeriesEpisodeSelector.EpisodeContent(episode: episode)
            }
            .imageOverlay {
                SeriesEpisodeSelector.EpisodeOverlay(episode: episode)
            }
//            .onSelect {
//                guard let mediaSource = episode.mediaSources?.first else { return }
//                mainRouter.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: episode, mediaSource: mediaSource))
//            }
        }
        .scrollBehavior(.continuousLeadingEdge)
        .insets(horizontal: EdgeInsets.defaultEdgePadding)
        .itemSpacing(EdgeInsets.defaultEdgePadding / 2)
        .onFirstAppear {
            print("here")
        }
    }
}
