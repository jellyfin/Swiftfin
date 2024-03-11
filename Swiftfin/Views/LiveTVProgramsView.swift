//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

struct LiveTVProgramsView: View {

    @EnvironmentObject
    private var programsRouter: LiveTVProgramsCoordinator.Router
    @StateObject
    var viewModel = LiveTVProgramsViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                if viewModel.recommendedItems.isNotEmpty {
                    let items = viewModel.recommendedItems
//                    PosterHStack(title: L10n.onNow, type: .portrait, items: items)
//                        .onSelect { item in
//                            if let chanId = item.channelId,
//                               let chan = viewModel.findChannel(id: chanId)
//                            {
                    ////                                self.viewModel.fetchVideoPlayerViewModel(item: chan) { playerViewModel in
                    ////                                    self.programsRouter.route(to: \.videoPlayer, playerViewModel)
                    ////                                }
//                            }
//                        }
                }
                if viewModel.seriesItems.isNotEmpty {
                    let items = viewModel.seriesItems
//                    PosterHStack(title: L10n.tvShows, type: .portrait, items: items)
//                        .onSelect { item in
//                            if let chanId = item.channelId,
//                               let chan = viewModel.findChannel(id: chanId)
//                            {
                    ////                                self.viewModel.fetchVideoPlayerViewModel(item: chan) { playerViewModel in
                    ////                                    self.programsRouter.route(to: \.videoPlayer, playerViewModel)
                    ////                                }
//                            }
//                        }
                }
                if viewModel.movieItems.isNotEmpty {
                    let items = viewModel.movieItems
//                    PosterHStack(title: L10n.movies, type: .portrait, items: items)
//                        .onSelect { item in
//                            if let chanId = item.channelId,
//                               let chan = viewModel.findChannel(id: chanId)
//                            {
                    ////                                self.viewModel.fetchVideoPlayerViewModel(item: chan) { playerViewModel in
                    ////                                    self.programsRouter.route(to: \.videoPlayer, playerViewModel)
                    ////                                }
//                            }
//                        }
                }
                if viewModel.sportsItems.isNotEmpty {
                    let items = viewModel.sportsItems
//                    PosterHStack(title: L10n.sports, type: .portrait, items: items)
//                        .onSelect { item in
//                            if let chanId = item.channelId,
//                               let chan = viewModel.findChannel(id: chanId)
//                            {
                    ////                                self.viewModel.fetchVideoPlayerViewModel(item: chan) { playerViewModel in
                    ////                                    self.programsRouter.route(to: \.videoPlayer, playerViewModel)
                    ////                                }
//                            }
//                        }
                }
                if viewModel.kidsItems.isNotEmpty {
                    let items = viewModel.kidsItems
//                    PosterHStack(title: L10n.kids, type: .portrait, items: items)
//                        .onSelect { item in
//                            if let chanId = item.channelId,
//                               let chan = viewModel.findChannel(id: chanId)
//                            {
                    ////                                self.viewModel.fetchVideoPlayerViewModel(item: chan) { playerViewModel in
                    ////                                    self.programsRouter.route(to: \.videoPlayer, playerViewModel)
                    ////                                }
//                            }
//                        }
                }
                if viewModel.newsItems.isNotEmpty {
                    let items = viewModel.newsItems
//                    PosterHStack(title: L10n.news, type: .portrait, items: items)
//                        .onSelect { item in
//                            if let chanId = item.channelId,
//                               let chan = viewModel.findChannel(id: chanId)
//                            {
                    ////                                self.viewModel.fetchVideoPlayerViewModel(item: chan) { playerViewModel in
                    ////                                    self.programsRouter.route(to: \.videoPlayer, playerViewModel)
                    ////                                }
//                            }
//                        }
                }
            }
        }
    }
}
