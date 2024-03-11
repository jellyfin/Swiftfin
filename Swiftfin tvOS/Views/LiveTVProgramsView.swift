//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Foundation
import SwiftUI

struct LiveTVProgramsView: View {

    @EnvironmentObject
    private var router: LiveTVProgramsCoordinator.Router

    @StateObject
    var viewModel: LiveTVProgramsViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                if viewModel.recommendedItems.isNotEmpty {
                    let items = viewModel.recommendedItems
                    Text("On Now")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.leading, 90)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            Spacer().frame(width: 45)
                            ForEach(items, id: \.id) { item in
                                Button {
                                    guard let channelID = item.channelID,
                                          let channel = viewModel.findChannel(id: channelID),
                                          let mediaSource = channel.mediaSources?.first else { return }

                                    router.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: channel, mediaSource: mediaSource))
                                } label: {
                                    LandscapeItemElement(item: item)
                                }
                                .buttonStyle(PlainNavigationLinkButtonStyle())
                            }
                            Spacer().frame(width: 45)
                        }
                    }.frame(height: 350)
                }
                if viewModel.seriesItems.isNotEmpty {
                    let items = viewModel.seriesItems
                    Text("Shows")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.leading, 90)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            Spacer().frame(width: 45)
                            ForEach(items, id: \.id) { item in
                                Button {
                                    guard let channelID = item.channelID,
                                          let channel = viewModel.findChannel(id: channelID),
                                          let mediaSource = channel.mediaSources?.first else { return }

                                    router.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: channel, mediaSource: mediaSource))
                                } label: {
                                    LandscapeItemElement(item: item)
                                }
                                .buttonStyle(PlainNavigationLinkButtonStyle())
                            }
                            Spacer().frame(width: 45)
                        }
                    }.frame(height: 350)
                }
                if viewModel.movieItems.isNotEmpty {
                    let items = viewModel.movieItems
                    Text("Movies")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.leading, 90)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            Spacer().frame(width: 45)
                            ForEach(items, id: \.id) { item in
                                Button {
                                    guard let channelID = item.channelID,
                                          let channel = viewModel.findChannel(id: channelID),
                                          let mediaSource = channel.mediaSources?.first else { return }

                                    router.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: channel, mediaSource: mediaSource))
                                } label: {
                                    LandscapeItemElement(item: item)
                                }
                                .buttonStyle(PlainNavigationLinkButtonStyle())
                            }
                            Spacer().frame(width: 45)
                        }
                    }.frame(height: 350)
                }
                if viewModel.sportsItems.isNotEmpty {
                    let items = viewModel.sportsItems
                    Text("Sports")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.leading, 90)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            Spacer().frame(width: 45)
                            ForEach(items, id: \.id) { item in
                                Button {
                                    guard let channelID = item.channelID,
                                          let channel = viewModel.findChannel(id: channelID),
                                          let mediaSource = channel.mediaSources?.first else { return }

                                    router.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: channel, mediaSource: mediaSource))
                                } label: {
                                    LandscapeItemElement(item: item)
                                }
                                .buttonStyle(PlainNavigationLinkButtonStyle())
                            }
                            Spacer().frame(width: 45)
                        }
                    }.frame(height: 350)
                }
                if viewModel.kidsItems.isNotEmpty {
                    let items = viewModel.kidsItems
                    Text("Kids")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.leading, 90)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            Spacer().frame(width: 45)
                            ForEach(items, id: \.id) { item in
                                Button {
                                    guard let channelID = item.channelID,
                                          let channel = viewModel.findChannel(id: channelID),
                                          let mediaSource = channel.mediaSources?.first else { return }

                                    router.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: channel, mediaSource: mediaSource))
                                } label: {
                                    LandscapeItemElement(item: item)
                                }
                                .buttonStyle(PlainNavigationLinkButtonStyle())
                            }
                            Spacer().frame(width: 45)
                        }
                    }.frame(height: 350)
                }
                if viewModel.newsItems.isNotEmpty {
                    let items = viewModel.newsItems
                    Text("News")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.leading, 90)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            Spacer().frame(width: 45)
                            ForEach(items, id: \.id) { item in
                                Button {
                                    guard let channelID = item.channelID,
                                          let channel = viewModel.findChannel(id: channelID),
                                          let mediaSource = channel.mediaSources?.first else { return }

                                    router.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: channel, mediaSource: mediaSource))
                                } label: {
                                    LandscapeItemElement(item: item)
                                }
                                .buttonStyle(PlainNavigationLinkButtonStyle())
                            }
                            Spacer().frame(width: 45)
                        }
                    }.frame(height: 350)
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .edgesIgnoringSafeArea(.horizontal)
    }
}
