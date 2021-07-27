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
import SwiftUIFocusGuide

struct MovieItemView: View {
    @ObservedObject var viewModel: MovieItemViewModel

    @State var actors: [BaseItemPerson] = []
    @State var studio: String?
    @State var director: String?

    @State var wrappedScrollView: UIScrollView?

    @StateObject var focusBag = SwiftUIFocusBag()

    @Namespace private var namespace

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
            ScrollView {
                LazyVStack(alignment: .leading) {
                    Text(viewModel.item.name ?? "")
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
                        Text(viewModel.item.getItemRuntime()).font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        if viewModel.item.officialRating != nil {
                            Text(viewModel.item.officialRating!).font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                .overlay(RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.secondary, lineWidth: 1))
                        }
                    }

                    HStack {
                        VStack(alignment: .trailing) {
                            if studio != nil {
                                Text("STUDIO")
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
                                Text("DIRECTOR")
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
                                Text("CAST")
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
                                    }
                                    Text(viewModel.isFavorited ? "Unfavorite" : "Favorite")
                                        .font(.caption)
                                }
                                VStack {
                                    NavigationLink(destination: VideoPlayerView(item: viewModel.item)) {
                                        MediaViewActionButton(icon: "play.fill", scrollView: $wrappedScrollView)
                                    }
                                    Text(viewModel.item.getItemProgressString() != "" ? "\(viewModel.item.getItemProgressString()) left" : "Play")
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
                                Spacer()
                            }
                            .padding(.top, 15)
                            .addFocusGuide(using: focusBag, name: "actionButtons", destinations: [.bottom: "moreLikeThis"], debug: false)
                        }
                    }.padding(.top, 50)

                    if !viewModel.similarItems.isEmpty {
                        Text("More Like This")
                            .font(.headline)
                            .fontWeight(.semibold)
                        ScrollView(.horizontal) {
                            LazyHStack {
                                Spacer().frame(width: 45)
                                ForEach(viewModel.similarItems, id: \.id) { similarItems in
                                    NavigationLink(destination: ItemView(item: similarItems)) {
                                        PortraitItemElement(item: similarItems)
                                    }.buttonStyle(PlainNavigationLinkButtonStyle())
                                }
                                Spacer().frame(width: 45)
                            }
                        }.padding(EdgeInsets(top: -30, leading: -90, bottom: 0, trailing: -90))
                        .addFocusGuide(using: focusBag, name: "moreLikeThis", destinations: [.top: "actionButtons"], debug: false)
                        .frame(height: 360)
                    }
                }.padding(EdgeInsets(top: 90, leading: 90, bottom: 0, trailing: 90))
            }.introspectScrollView { scrollView in
                wrappedScrollView = scrollView
            }
        }.onAppear(perform: onAppear)
        .focusScope(namespace)
    }
}

extension UIScrollView {
    func scrollToTop() {
        let desiredOffset = CGPoint(x: 0, y: 0)
        setContentOffset(desiredOffset, animated: true)
   }
}
