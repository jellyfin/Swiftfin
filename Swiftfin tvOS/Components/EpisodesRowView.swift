//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import JellyfinAPI
import SwiftUI

struct EpisodesRowView: View {
    
    @EnvironmentObject var itemRouter: ItemCoordinator.Router
    @ObservedObject var viewModel: EpisodesRowViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text(viewModel.selectedSeason?.name ?? "Episodes")
                .font(.title3)
                .padding(.horizontal, 50)
            
            ScrollView(.horizontal) {
                ScrollViewReader { reader in
                    HStack(alignment: .top) {
                        if viewModel.isLoading {
                            VStack(alignment: .leading) {

                                ZStack {
                                    Color.secondary.ignoresSafeArea()
                                    
                                    ProgressView()
                                }
                                    .mask(Rectangle().frame(width: 500, height: 280))
                                    .frame(width: 500, height: 280)

                                VStack(alignment: .leading) {
                                    Text("S-E-")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("--")
                                        .font(.footnote)
                                        .padding(.bottom, 1)
                                    Text("--")
                                        .font(.caption)
                                        .fontWeight(.light)
                                        .lineLimit(4)
                                }
                                .padding(.horizontal)

                                Spacer()
                            }
                            .frame(width: 500)
                            .focusable()
                        } else if let selectedSeason = viewModel.selectedSeason {
                            if viewModel.seasonsEpisodes[selectedSeason]!.isEmpty {
                                VStack(alignment: .leading) {

                                    Color.secondary
                                        .mask(Rectangle().frame(width: 500, height: 280))
                                        .frame(width: 500, height: 280)

                                    VStack(alignment: .leading) {
                                        Text("--")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("No episodes available")
                                            .font(.footnote)
                                            .padding(.bottom, 1)
                                    }
                                    .padding(.horizontal)

                                    Spacer()
                                }
                                .frame(width: 500)
                                .focusable()
                            } else {
                                ForEach(viewModel.seasonsEpisodes[selectedSeason]!, id:\.self) { episode in
                                    Button {
                                        itemRouter.route(to: \.item, episode)
                                    } label: {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading) {

                                                ImageView(src: episode.getBackdropImage(maxWidth: 500),
                                                          bh: episode.getBackdropImageBlurHash())
                                                    .mask(Rectangle().frame(width: 500, height: 280))
                                                    .frame(width: 500, height: 280)

                                                VStack(alignment: .leading) {
                                                    Text(episode.getEpisodeLocator() ?? "")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    Text(episode.name ?? "")
                                                        .font(.footnote)
                                                        .padding(.bottom, 1)
                                                    Text(episode.overview ?? "")
                                                        .font(.caption)
                                                        .fontWeight(.light)
                                                        .lineLimit(4)
                                                }
                                                .padding(.horizontal)

                                                Spacer()
                                            }
                                            .frame(width: 500)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .id(episode.name)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 50)
                    .padding(.vertical)
                    .onChange(of: viewModel.selectedSeason) { _ in
                        if viewModel.selectedSeason?.id == viewModel.episodeItemViewModel.item.seasonId {
                            reader.scrollTo(viewModel.episodeItemViewModel.item.name)
                        }
                    }
                    .onChange(of: viewModel.seasonsEpisodes) { _ in
                        if viewModel.selectedSeason?.id == viewModel.episodeItemViewModel.item.seasonId {
                            reader.scrollTo(viewModel.episodeItemViewModel.item.name)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.horizontal)
            }
        }
    }
}
