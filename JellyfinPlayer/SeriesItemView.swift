/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI

struct SeriesItemView: View {
    @StateObject var viewModel: SeriesItemViewModel
    @State private var orientation = UIDeviceOrientation.unknown
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass

    @State private var tracks: [GridItem] = Array(repeating: .init(.flexible()), count: Int(UIScreen.main.bounds.size.width) / 125)

    @ViewBuilder
    var portraitHeaderView: some View {
        ImageView(src: viewModel.item
            .getBackdropImage(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 622 : Int(UIScreen.main.bounds.width)),
            bh: viewModel.item.getBackdropImageBlurHash())
            .opacity(0.4)
            .blur(radius: 2.0)
    }

    var portraitHeaderOverlayView: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ImageView(src: viewModel.item.getPrimaryImage(maxWidth: 120), bh: viewModel.item.getPrimaryImageBlurHash())
                .frame(width: 120, height: 180)
                .cornerRadius(10)
            VStack(alignment: .leading) {
                Text(viewModel.item.name ?? "").font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: -4)
                HStack {
                    Text(String(viewModel.item.productionYear ?? 0)).font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    if let officialRating = viewModel.item.officialRating {
                        Text(officialRating).font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                            .overlay(RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.secondary, lineWidth: 1))
                    }
                }
            }.offset(y: -32)
        }.padding(.horizontal, 16)
            .offset(y: 22)
    }

    func recalcTracks() {
        tracks = Array(repeating: .init(.flexible()), count: Int(UIScreen.main.bounds.size.width) / 125)
    }

    var innerBody: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if let firstTagline = viewModel.item.taglines?.first {
                    Text(firstTagline).font(.body).italic()
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 16)
                }
                if let genreItems = viewModel.item.genreItems,
                   !genreItems.isEmpty
                {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 8) {
                            Text("Genres:").font(.callout).fontWeight(.semibold)
                            ForEach(genreItems, id: \.id) { genre in
                                NavigationLink(destination: LazyView {
                                    LibraryView(viewModel: .init(genre: genre), title: genre.name ?? "")
                                }) {
                                    Text(genre.name ?? "").font(.footnote)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 8)
                }
                Text(viewModel.item.overview ?? "")
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 16)
                Text("Seasons")
                    .font(.callout).fontWeight(.semibold)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 24)
            LazyVGrid(columns: tracks) {
                ForEach(viewModel.seasons, id: \.id) { season in
                    PortraitItemView(item: season)
                }
            }
            .padding(.bottom, 16)
            .padding(.horizontal, 8)
            LazyVStack(alignment: .leading, spacing: 0) {
                if let people = viewModel.item.people,
                   !people.isEmpty
                {
                    Text("CAST")
                        .font(.callout).fontWeight(.semibold)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(people, id: \.self) { person in
                                if person.type == "Actor" {
                                    NavigationLink(destination: LazyView {
                                        LibraryView(viewModel: .init(person: person), title: person.name ?? "")
                                    }) {
                                        VStack {
                                            ImageView(src: person
                                                .getImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: 100),
                                                bh: person.getBlurHash())
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(10)
                                            Text(person.name ?? "").font(.footnote).fontWeight(.regular).lineLimit(1)
                                                .frame(width: 100).foregroundColor(Color.primary)
                                            if let role = person.role,
                                               !role.isEmpty
                                            {
                                                Text(role).font(.caption).fontWeight(.medium).lineLimit(1)
                                                    .foregroundColor(Color.secondary).frame(width: 100)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
                if let studios = viewModel.item.studios,
                   !studios.isEmpty
                {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            Text("Studios:").font(.callout).fontWeight(.semibold)
                            ForEach(studios, id: \.id) { studio in
                                NavigationLink(destination: LazyView {
                                    LibraryView(viewModel: .init(studio: studio), title: studio.name ?? "")
                                }) {
                                    Text(studio.name ?? "").font(.footnote)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
                if !viewModel.similarItems.isEmpty {
                    Text("More Like This")
                        .font(.callout).fontWeight(.semibold)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.similarItems, id: \.self) { similarItem in
                                NavigationLink(destination: LazyView { ItemView(item: similarItem) }) {
                                    PortraitItemView(item: similarItem)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
            }
        }
    }

    var landscapeView: some View {
        GeometryReader { geometry in
            ZStack {
                ImageView(src: viewModel.item.getBackdropImage(maxWidth: 200),
                          bh: viewModel.item.getBackdropImageBlurHash())
                    .opacity(0.4)
                    .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
                           height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 4)
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading) {
                        ImageView(src: viewModel.item.getPrimaryImage(maxWidth: 120),
                                  bh: viewModel.item.getPrimaryImageBlurHash())
                            .frame(width: 120, height: 180)
                            .cornerRadius(10)
                        HStack {
                            Text(String(viewModel.item.productionYear ?? 0)).font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            if let officialRating = viewModel.item.officialRating {
                                Text(officialRating).font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                    .overlay(RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.secondary, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.top, 16)
                    innerBody
                }
            }
        }
    }

    var body: some View {
        if viewModel.isLoading {
            ProgressView()
        } else {
            Group {
                if hSizeClass == .compact && vSizeClass == .regular {
                    ParallaxHeaderScrollView(header: portraitHeaderView,
                                             staticOverlayView: portraitHeaderOverlayView,
                                             overlayAlignment: .bottomLeading,
                                             headerHeight: UIScreen.main.bounds.width * 0.5625) {
                        innerBody
                    }
                } else {
                    landscapeView
                }
            }
            .onRotate {
                orientation = $0
                recalcTracks()
            }
            .overrideViewPreference(.unspecified)
            .navigationTitle(viewModel.item.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
