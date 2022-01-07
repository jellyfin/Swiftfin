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

struct SingleSeasonEpisodesRowView: View {
    
    @EnvironmentObject var itemRouter: ItemCoordinator.Router
    @ObservedObject var viewModel: SingleSeasonEpisodesRowViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("Episodes")
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
                        } else if viewModel.episodes.isEmpty {
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
                                ForEach(viewModel.episodes, id:\.self) { episode in
                                    Button {
                                        itemRouter.route(to: \.item, episode)
                                    } label: {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading) {

                                                ImageView(src: episode.getBackdropImage(maxWidth: 445),
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
                    .padding(.horizontal, 50)
                    .padding(.vertical)
                }
                .edgesIgnoringSafeArea(.horizontal)
            }
        }
    }
}
