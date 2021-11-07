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

struct MovieItemView: View {
    @ObservedObject var viewModel: MovieItemViewModel

    @State var actors: [BaseItemPerson] = []
    @State var studio: String?
    @State var director: String?

    @State var wrappedScrollView: UIScrollView?

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
                .ignoresSafeArea()
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
                                R.string.localizable.studio.text
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
                                R.string.localizable.director.text
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
                                R.string.localizable.cast.text
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

                            MediaPlayButtonRowView(viewModel: viewModel, wrappedScrollView: wrappedScrollView)
                            .padding(.top, 15)
                        }
                    }.padding(.top, 50)

                    if !viewModel.similarItems.isEmpty {
                        R.string.localizable.moreLikeThis.text
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
