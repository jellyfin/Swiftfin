//
 /*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI
import JellyfinAPI

struct SeasonItemView: View {
    
    @EnvironmentObject var itemRouter: ItemCoordinator.Router
    @ObservedObject var viewModel: SeasonItemViewModel
    @State var wrappedScrollView: UIScrollView?

    @Environment(\.resetFocus) var resetFocus
    @Namespace private var namespace

    var body: some View {
        ZStack {
            ImageView(src: viewModel.item.getSeriesBackdropImage(maxWidth: 1920), bh: viewModel.item.getSeriesBackdropImageBlurHash())
                .opacity(0.4)
                .ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading) {
                    Text("\(viewModel.item.seriesName ?? "") • \(viewModel.item.name ?? "")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    HStack {
                        if viewModel.item.productionYear != nil {
                            Text(String(viewModel.item.productionYear!)).font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        if viewModel.item.officialRating != nil {
                            Text(viewModel.item.officialRating!).font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                .overlay(RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.secondary, lineWidth: 1))
                        }
                        if viewModel.item.communityRating != nil {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.subheadline)
                                Text(String(viewModel.item.communityRating!)).font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    VStack(alignment: .leading) {
                        if !(viewModel.item.taglines ?? []).isEmpty {
                            Text(viewModel.item.taglines?.first ?? "")
                                .font(.body)
                                .italic()
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        Text(viewModel.item.overview ?? "")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        HStack {
                            VStack {
                                Button {
                                    viewModel.updateFavoriteState()
                                } label: {
                                    MediaViewActionButton(icon: "heart.fill", scrollView: $wrappedScrollView, iconColor: viewModel.isFavorited ? .red : .white)
                                }.prefersDefaultFocus(in: namespace)
                                Text(viewModel.isFavorited ? "Unfavorite" : "Favorite")
                                    .font(.caption)
                            }

                            VStack {
                                Button {
                                    viewModel.updateWatchState()
                                } label: {
                                    MediaViewActionButton(icon: "eye.fill", scrollView: $wrappedScrollView, iconColor: viewModel.isWatched ? .red : .white)
                                }
                                Text(viewModel.isWatched ? "Unwatch" : "Mark Watched")
                                    .font(.caption)
                            }
                        }.padding(.top, 15)
                        Spacer()
                    }.padding(.top, 50)

                    if !viewModel.episodes.isEmpty {
                        L10n.episodes.text
                            .font(.headline)
                            .fontWeight(.semibold)
                        ScrollView(.horizontal) {
                            LazyHStack {
                                Spacer().frame(width: 45)
                                
                                ForEach(viewModel.episodes, id: \.id) { episode in
                                    
                                    Button {
                                        itemRouter.route(to: \.item, episode)
                                    } label: {
                                        LandscapeItemElement(item: episode, inSeasonView: true)
                                    }
                                    .buttonStyle(PlainNavigationLinkButtonStyle())
                                }
                                Spacer().frame(width: 45)
                            }
                        }.padding(EdgeInsets(top: -30, leading: -90, bottom: 0, trailing: -90))
                        .frame(height: 360)
                    }
                }.padding(EdgeInsets(top: 90, leading: 90, bottom: 45, trailing: 90))
            }
        }
    }
}
