/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import Combine
import JellyfinAPI

struct SeasonItemView: View {
    @StateObject
    var tempViewModel = ViewModel()
    @State private var orientation = UIDeviceOrientation.unknown
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass

    var item: BaseItemDto = BaseItemDto()
    @State private var episodes: [BaseItemDto] = []

    @State private var isLoading: Bool = true
    @State private var viewDidLoad: Bool = false

    init(item: BaseItemDto) {
        self.item = item
    }

    func onAppear() {
        if viewDidLoad {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            TvShowsAPI.getEpisodes(seriesId: item.seriesId ?? "", userId: SessionManager.current.user.user_id!, fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people], seasonId: item.id ?? "")
                .sink(receiveCompletion: { completion in
                    print(completion)
                    isLoading = false
                }, receiveValue: { response in
                    viewDidLoad = true
                    episodes = response.items ?? []
                })
                .store(in: &tempViewModel.cancellables)
        }
    }

    @ViewBuilder
    var portraitHeaderView: some View {
        if isLoading {
            EmptyView()
        } else {
            ImageView(src: item.getSeriesBackdropImage(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 622 : Int(UIScreen.main.bounds.width)), bh: item.getSeriesBackdropImageBlurHash())
                .opacity(0.4)
                .blur(radius: 2.0)
        }
    }

    var portraitHeaderOverlayView: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ImageView(src: item.getPrimaryImage(maxWidth: 120), bh: item.getPrimaryImageBlurHash())
                .frame(width: 120, height: 180)
                .cornerRadius(10)
            VStack(alignment: .leading) {
                Text(item.name ?? "").font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: -4)
                if item.productionYear != nil {
                    Text(String(item.productionYear!)).font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }.offset(y: -32)
        }.padding(.horizontal, 16)
        .offset(y: 22)
    }

    @ViewBuilder
    var innerBody: some View {
        if hSizeClass == .compact && vSizeClass == .regular {
            ParallaxHeaderScrollView(header: portraitHeaderView,
                                     staticOverlayView: portraitHeaderOverlayView,
                                     overlayAlignment: .bottomLeading,
                                     headerHeight: UIScreen.main.bounds.width * 0.5625) {
                LazyVStack(alignment: .leading) {
                    if !(item.taglines ?? []).isEmpty {
                        Text(item.taglines!.first!).font(.body).italic().padding(.top, 7)
                            .fixedSize(horizontal: false, vertical: true).padding(.leading, 16)
                            .padding(.trailing, 16)
                    }
                    Text(item.overview ?? "").font(.footnote).padding(.top, 3)
                        .fixedSize(horizontal: false, vertical: true).padding(.bottom, 3).padding(.leading, 16)
                        .padding(.trailing, 16)
                    ForEach(episodes, id: \.id) { episode in
                        NavigationLink(destination: ItemView(item: episode)) {
                            HStack {
                                ImageView(src: episode.getPrimaryImage(maxWidth: 150), bh: episode.getPrimaryImageBlurHash())
                                    .shadow(radius: 5)
                                    .frame(width: 150, height: 90)
                                    .cornerRadius(10)
                                    .overlay(
                                        Rectangle()
                                            .fill(Color(red: 172/255, green: 92/255, blue: 195/255))
                                            .mask(ProgressBar())
                                            .frame(width: CGFloat(episode.userData!.playedPercentage ?? 0 * 1.5), height: 7)
                                            .padding(0), alignment: .bottomLeading
                                    )
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("S\(String(episode.parentIndexNumber ?? 0)):E\(String(episode.indexNumber ?? 0))").font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(episode.name ?? "").font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(episode.getItemRuntime()).font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(episode.overview ?? "").font(.footnote).foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true).lineLimit(4)
                                    Spacer()
                                }.padding(.trailing, 20).offset(y: 2)
                            }.offset(x: 12, y: 0)
                        }
                    }
                    if !(item.studios ?? []).isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                Text("Studios:").font(.callout).fontWeight(.semibold)
                                ForEach(item.studios!, id: \.id) { studio in
                                    NavigationLink(destination: LazyView {
                                        LibraryView(withStudio: studio)
                                    }) {
                                        Text(studio.name ?? "").font(.footnote)
                                    }
                                }
                            }.padding(.leading, 16).padding(.trailing, 16)
                        }
                    }
                    Spacer().frame(height: 10)
                }
                .padding(.leading, 2)
                .padding(.top, 20)
            }
        } else {
            GeometryReader { geometry in
                ZStack {
                    ImageView(src: item.getSeriesBackdropImage(maxWidth: 200), bh: item.getSeriesBackdropImageBlurHash())
                        .opacity(0.4)
                        .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
                               height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                        .edgesIgnoringSafeArea(.all)
                        .blur(radius: 4)
                    HStack {
                        VStack(alignment: .leading) {
                            Spacer().frame(height: 16)
                            ImageView(src: item.getPrimaryImage(maxWidth: 120), bh: item.getPrimaryImageBlurHash())
                                .frame(width: 120, height: 180)
                                .cornerRadius(10)
                            Spacer().frame(height: 4)
                            if item.productionYear != nil {
                                Text(String(item.productionYear!)).font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        ScrollView {
                            Spacer().frame(height: 16)
                            LazyVStack(alignment: .leading) {
                                if !(item.taglines ?? []).isEmpty {
                                    Text(item.taglines!.first!).font(.body).italic().padding(.top, 7)
                                        .fixedSize(horizontal: false, vertical: true).padding(.leading, 16)
                                        .padding(.trailing, 16)
                                }
                                Text(item.overview ?? "").font(.footnote).padding(.top, 3)
                                    .fixedSize(horizontal: false, vertical: true).padding(.bottom, 3).padding(.leading, 16)
                                    .padding(.trailing, 16)
                                ForEach(episodes, id: \.id) { episode in
                                    NavigationLink(destination: ItemView(item: episode)) {
                                        HStack {
                                            ImageView(src: episode.getPrimaryImage(maxWidth: 150), bh: episode.getPrimaryImageBlurHash())
                                                .shadow(radius: 5)
                                                .frame(width: 150, height: 90)
                                                .cornerRadius(10)
                                                .overlay(
                                                    Rectangle()
                                                        .fill(Color(red: 172/255, green: 92/255, blue: 195/255))
                                                        .mask(ProgressBar())
                                                        .frame(width: CGFloat(episode.userData!.playedPercentage ?? 0 * 1.5), height: 7)
                                                        .padding(0), alignment: .bottomLeading
                                                )
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Text("S\(String(episode.parentIndexNumber ?? 0)):E\(String(episode.indexNumber ?? 0))").font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                    Spacer()
                                                    Text(episode.name ?? "").font(.subheadline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.primary)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .lineLimit(1)
                                                    Spacer()
                                                    Text(episode.getItemRuntime()).font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                                Spacer()
                                                Text(episode.overview ?? "").font(.footnote).foregroundColor(.secondary)
                                                    .fixedSize(horizontal: false, vertical: true).lineLimit(4)
                                                Spacer()
                                            }.padding(.trailing, 20).offset(y: 2)
                                        }.offset(x: 12, y: 0)
                                    }
                                }
                                if !(item.studios ?? []).isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            Text("Studios:").font(.callout).fontWeight(.semibold)
                                            ForEach(item.studios!, id: \.id) { studio in
                                                NavigationLink(destination: LazyView {
                                                    LibraryView(withStudio: studio)
                                                }) {
                                                    Text(studio.name ?? "").font(.footnote)
                                                }
                                            }
                                        }.padding(.leading, 16).padding(.trailing, 16)
                                    }
                                }
                                Spacer().frame(height: 95)
                            }.frame(maxHeight: .infinity)
                        }.padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                    }.padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 0)
                }
            }
        }
    }

    var body: some View {
        if isLoading {
            ProgressView()
                .onAppear(perform: onAppear)
        } else {
            innerBody
                .onRotate {
                    orientation = $0
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("\(item.name ?? "") - \(item.seriesName ?? "")")
        }
    }
}
