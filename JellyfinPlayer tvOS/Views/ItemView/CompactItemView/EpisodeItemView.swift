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

struct EpisodeItemView: View {
    
    @EnvironmentObject var itemRouter: ItemCoordinator.Router
    @ObservedObject var viewModel: EpisodeItemViewModel

    @State var actors: [BaseItemPerson] = []
    @State var studio: String?
    @State var director: String?

    func onAppear() {
        actors = []
        director = nil
        studio = nil
        var actor_index = 0
        viewModel.item.people?.forEach { person in
            if person.type == "Actor" {
                if actor_index < 4 {
                    actors.append(person)
                }
                actor_index = actor_index + 1
            }
            if person.type == "Director" {
                director = person.name ?? ""
            }
        }

        studio = viewModel.item.studios?.first?.name ?? nil
    }

    var body: some View {
        ZStack {
            ImageView(src: viewModel.item.getBackdropImage(maxWidth: 1920), bh: viewModel.item.getBackdropImageBlurHash())
                .opacity(0.4)
                .ignoresSafeArea()
            LazyVStack(alignment: .leading) {
                Text(viewModel.item.name ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(viewModel.item.seriesName ?? "")
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                HStack {
                    if viewModel.item.productionYear != nil {
                        Text(String(viewModel.item.productionYear!)).font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    if let runtime = viewModel.item.getItemRuntime() {
                        Text(runtime).font(.subheadline)
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
                    Spacer()
                }.padding(.top, -15)

                HStack(alignment: .top) {
                    VStack(alignment: .trailing) {
                        if studio != nil {
                            L10n.studio.text
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text(studio!)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 40)
                        }

                        if director != nil {
                            L10n.director.text
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text(director!)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 40)
                        }

                        if !actors.isEmpty {
                            L10n.cast.text
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            ForEach(actors, id: \.id) { person in
                                Text(person.name!)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    VStack(alignment: .leading) {
                        Text(viewModel.item.overview ?? "")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        MediaPlayButtonRowView(viewModel: viewModel)
                            .environmentObject(itemRouter)
                    }
                }.padding(.top, 50)

                if !viewModel.similarItems.isEmpty {
                    L10n.moreLikeThis.text
                        .font(.headline)
                        .fontWeight(.semibold)
                    ScrollView(.horizontal) {
                        LazyHStack {
                            Spacer().frame(width: 45)
                            ForEach(viewModel.similarItems, id: \.id) { similarItem in
                                Button {
                                    itemRouter.route(to: \.item, similarItem)
                                } label: {
                                    PortraitItemElement(item: similarItem)
                                }
                                .buttonStyle(PlainNavigationLinkButtonStyle())
                            }
                            Spacer().frame(width: 45)
                        }
                    }.padding(EdgeInsets(top: -30, leading: -90, bottom: 0, trailing: -90))
                    .frame(height: 360)
                }
                Spacer()
                Spacer()
            }.padding(EdgeInsets(top: 90, leading: 90, bottom: 0, trailing: 90))
        }.onAppear(perform: onAppear)
    }
}
