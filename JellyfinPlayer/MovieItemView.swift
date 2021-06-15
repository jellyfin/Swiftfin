/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import JellyfinAPI
import Combine

struct MovieItemView: View {
    @State private var orientation = UIDeviceOrientation.unknown
    @EnvironmentObject private var playbackInfo: VideoPlayerItem

    var item: BaseItemDto

    @State private var settingState: Bool = true
    @State private var watched: Bool = false {
        didSet {
            var tempCancellables = Set<AnyCancellable>()
            
            if !settingState {
                if watched == true {
                    PlaystateAPI.markPlayedItem(userId: SessionManager.current.userID!, itemId: item.id!)
                        .sink(receiveCompletion: { completion in
                            print(completion)
                        }, receiveValue: { _ in
                        })
                        .store(in: &tempCancellables)
                } else {
                    PlaystateAPI.markUnplayedItem(userId: SessionManager.current.userID!, itemId: item.id!)
                        .sink(receiveCompletion: { completion in
                            print(completion)
                        }, receiveValue: { _ in
                        })
                        .store(in: &tempCancellables)
                }
            }
        }
    }

    @State
    private var favorite: Bool = false {
        didSet {
            var tempCancellables = Set<AnyCancellable>()
            
            if !settingState {
                if favorite == true {
                    UserLibraryAPI.markFavoriteItem(userId: SessionManager.current.userID!, itemId: item.id!)
                        .sink(receiveCompletion: { completion in
                            print(completion)
                        }, receiveValue: { _ in
                        })
                        .store(in: &tempCancellables)
                } else {
                    UserLibraryAPI.unmarkFavoriteItem(userId: SessionManager.current.userID!, itemId: item.id!)
                        .sink(receiveCompletion: { completion in
                            print(completion)
                        }, receiveValue: { _ in
                        })
                        .store(in: &tempCancellables)
                }
            }
        }
    }

    var portraitHeaderView: some View {
        ImageView(src: item.getBackdropImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 622 : Int(UIScreen.main.bounds.width)), bh: item.getBackdropImageBlurHash())
            .opacity(0.4)
            .blur(radius: 2.0)
    }

    var portraitHeaderOverlayView: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom, spacing: 12) {
                ImageView(src: item.getPrimaryImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: 120))
                    .frame(width: 120, height: 180)
                    .cornerRadius(10)
                VStack(alignment: .leading) {
                    Spacer()
                    Text(item.name ?? "").font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .offset(y: 5)
                    HStack {
                        if item.productionYear != nil {
                            Text(String(item.productionYear ?? 0)).font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Text(item.getItemRuntime()).font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        if item.officialRating != nil {
                            Text(item.officialRating!).font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                .overlay(RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.secondary, lineWidth: 1))
                        }
                    }
                }
                .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 98 : 30)
            }
            HStack {
                // Play button
                Button {
                    self.playbackInfo.itemToPlay = item
                    self.playbackInfo.shouldShowPlayer = true
                } label: {
                    HStack {
                        Text(item.getItemProgressString() == "" ? "Play" : "\(item.getItemProgressString()) left")
                            .foregroundColor(Color.white).font(.callout).fontWeight(.semibold)
                        Image(systemName: "play.fill").foregroundColor(Color.white).font(.system(size: 20))
                    }
                    .frame(width: 120, height: 35)
                    .background(Color(red: 172 / 255, green: 92 / 255, blue: 195 / 255))
                    .cornerRadius(10)
                }.buttonStyle(PlainButtonStyle())
                    .frame(width: 120, height: 35)
                Spacer()
                HStack {
                    Button {
                        favorite.toggle()
                    } label: {
                        if !favorite {
                            Image(systemName: "heart").foregroundColor(Color.primary).font(.system(size: 20))
                        } else {
                            Image(systemName: "heart.fill").foregroundColor(Color(UIColor.systemRed))
                                .font(.system(size: 20))
                        }
                    }
                    Button {
                        watched.toggle()
                    } label: {
                        if watched {
                            Image(systemName: "checkmark.rectangle.fill").foregroundColor(Color.primary)
                                .font(.system(size: 20))
                        } else {
                            Image(systemName: "xmark.rectangle").foregroundColor(Color.primary)
                                .font(.system(size: 20))
                        }
                    }
                }
            }.padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? -189 : -64)
    }

    var body: some View {
        VStack(alignment: .leading) {
            if orientation == .portrait {
                ParallaxHeaderScrollView(header: portraitHeaderView, staticOverlayView: portraitHeaderOverlayView, overlayAlignment: .bottomLeading, headerHeight: UIDevice.current.userInterfaceIdiom == .pad ? 350 : UIScreen.main.bounds.width * 0.5625) {
                    VStack(alignment: .leading) {
                        Spacer()
                            .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 135 : 40)
                            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 54 : 24)
                        if !(item.taglines ?? []).isEmpty {
                            Text(item.taglines!.first!).font(.body).italic().padding(.top, 7)
                                .fixedSize(horizontal: false, vertical: true).padding(.leading, 16)
                                .padding(.trailing, 16)
                        }
                        Text(item.overview ?? "").font(.footnote).padding(.top, 3)
                            .fixedSize(horizontal: false, vertical: true).padding(.bottom, 3).padding(.leading, 16)
                            .padding(.trailing, 16)
                        if !(item.genreItems ?? []).isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    Text("Genres:").font(.callout).fontWeight(.semibold)
                                    ForEach(item.genreItems!, id: \.id) { genre in
                                        NavigationLink(destination: LazyView {
                                            LibraryView(withGenre: genre)
                                        }) {
                                            Text(genre.name ?? "").font(.footnote)
                                        }
                                    }
                                }.padding(.leading, 16).padding(.trailing, 16)
                            }
                        }
                        if !(item.people ?? []).isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                VStack {
                                    Spacer().frame(height: 8)
                                    HStack {
                                        Spacer().frame(width: 16)
                                        ForEach(item.people!, id: \.self) { person in
                                            if person.type! == "Actor" {
                                                NavigationLink(destination: LazyView {
                                                    LibraryView(withPerson: person)
                                                }) {
                                                    VStack {
                                                        ImageView(src: person.getImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: 100), bh: person.getBlurHash())
                                                            .frame(width: 100, height: 100)
                                                            .cornerRadius(10)
                                                        Text(person.name ?? "").font(.footnote).fontWeight(.regular).lineLimit(1)
                                                            .frame(width: 100).foregroundColor(Color.primary)
                                                        if person.role != "" {
                                                            Text(person.role!).font(.caption).fontWeight(.medium).lineLimit(1)
                                                                .foregroundColor(Color.secondary).frame(width: 100)
                                                        }
                                                    }
                                                }
                                                Spacer().frame(width: 10)
                                            }
                                        }
                                        Spacer().frame(width: 16)
                                    }
                                }
                            }.padding(.top, -3)
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
                        Spacer().frame(height: 3)
                    }
                }
            } else {
                GeometryReader { geometry in
                    ZStack {
                        ImageView(src: item.getBackdropImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: 200), bh: item.getBackdropImageBlurHash())
                            .opacity(0.3)
                            .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
                                   height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                            .edgesIgnoringSafeArea(.all)
                            .blur(radius: 4)
                        HStack {
                            VStack {
                                ImageView(src: item.getPrimaryImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: 120), bh: item.getPrimaryImageBlurHash())
                                    .frame(width: 120, height: 180)
                                    .cornerRadius(10)
                                Spacer().frame(height: 15)
                                Button {
                                    self.playbackInfo.itemToPlay = item
                                    self.playbackInfo.shouldShowPlayer = true
                                } label: {
                                    HStack {
                                        Text(item.getItemProgressString() == "" ? "Play" : "\(item.getItemProgressString()) left")
                                            .foregroundColor(Color.white).font(.callout).fontWeight(.semibold)
                                        Image(systemName: "play.fill").foregroundColor(Color.white).font(.system(size: 20))
                                    }
                                    .frame(width: 120, height: 35)
                                    .background(Color(red: 172 / 255, green: 92 / 255, blue: 195 / 255))
                                    .cornerRadius(10)
                                }.buttonStyle(PlainButtonStyle())
                                    .frame(width: 120, height: 35)
                                Spacer()
                            }
                            ScrollView {
                                VStack(alignment: .leading) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(item.name ?? "").font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .offset(x: 14, y: 0)
                                            Spacer().frame(height: 1)
                                            HStack {
                                                if item.productionYear != nil {
                                                    Text(String(item.productionYear ?? 0)).font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                                Text(item.getItemRuntime()).font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                                if item.officialRating != nil {
                                                    Text(item.officialRating!).font(.subheadline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                        .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                                        .overlay(RoundedRectangle(cornerRadius: 2)
                                                            .stroke(Color.secondary, lineWidth: 1))
                                                }
                                                if item.communityRating != nil {
                                                    HStack {
                                                        Image(systemName: "star").foregroundColor(.secondary)
                                                        Text(String(item.communityRating!)).font(.subheadline)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(1)
                                                            .offset(x: -7, y: 0.7)
                                                    }
                                                }
                                                Spacer()
                                            }.frame(maxWidth: .infinity, alignment: .leading)
                                                .offset(x: 14)
                                        }.frame(maxWidth: .infinity, alignment: .leading)
                                        Spacer()
                                        HStack {
                                            Button {
                                                favorite.toggle()
                                            } label: {
                                                if !favorite {
                                                    Image(systemName: "heart").foregroundColor(Color.primary)
                                                        .font(.system(size: 20))
                                                } else {
                                                    Image(systemName: "heart.fill").foregroundColor(Color(UIColor.systemRed))
                                                        .font(.system(size: 20))
                                                }
                                            }
                                            Button {
                                                watched.toggle()
                                            } label: {
                                                if watched {
                                                    Image(systemName: "checkmark.rectangle.fill").foregroundColor(Color.primary)
                                                        .font(.system(size: 20))
                                                } else {
                                                    Image(systemName: "xmark.rectangle").foregroundColor(Color.primary)
                                                        .font(.system(size: 20))
                                                }
                                            }
                                        }
                                    }.padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                    if !(item.taglines ?? []).isEmpty {
                                        Text(item.taglines!.first!).font(.body).italic().padding(.top, 3)
                                            .fixedSize(horizontal: false, vertical: true).padding(.leading, 16)
                                            .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                    }
                                    Text(item.overview ?? "").font(.footnote).padding(.top, 3)
                                        .fixedSize(horizontal: false, vertical: true).padding(.bottom, 3).padding(.leading, 16)
                                        .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                    if !(item.genreItems ?? []).isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack {
                                                Text("Genres:").font(.callout).fontWeight(.semibold)
                                                ForEach(item.genreItems!, id: \.id) { genre in
                                                    NavigationLink(destination: LazyView {
                                                        LibraryView(withGenre: genre)
                                                    }) {
                                                        Text(genre.name ?? "").font(.footnote)
                                                    }
                                                }
                                            }
                                            .padding(.leading, 16)
                                            .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                        }
                                    }
                                    if !(item.people ?? []).isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            VStack {
                                                Spacer().frame(height: 8)
                                                HStack {
                                                    Spacer().frame(width: 16)
                                                    ForEach(item.people!, id: \.self) { person in
                                                        if person.type! == "Actor" {
                                                            NavigationLink(destination: LazyView {
                                                                LibraryView(withPerson: person)
                                                            }) {
                                                                VStack {
                                                                    ImageView(src: person.getImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: 100), bh: person.getBlurHash())
                                                                        .frame(width: 100, height: 100)
                                                                        .cornerRadius(10)
                                                                    Text(person.name ?? "").font(.footnote).fontWeight(.regular).lineLimit(1)
                                                                        .frame(width: 100).foregroundColor(Color.primary)
                                                                    if person.role != "" {
                                                                        Text(person.role!).font(.caption).fontWeight(.medium).lineLimit(1)
                                                                            .foregroundColor(Color.secondary).frame(width: 100)
                                                                    }
                                                                }
                                                            }
                                                            Spacer().frame(width: 10)
                                                        }
                                                    }
                                                    Spacer().frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                                }
                                            }
                                        }.padding(.top, -3)
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
                                            }
                                            .padding(.leading, 16)
                                            .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                                        }
                                    }
                                    Spacer().frame(height: 105)
                                }.frame(maxHeight: .infinity)
                            }
                        }.padding(.top, 16).padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                            .edgesIgnoringSafeArea(.leading)
                    }
                }
            }
        }
        .onAppear(perform: {
            favorite = item.userData?.isFavorite ?? false
            watched = item.userData?.played ?? false
            settingState = false
        })
        .onRotate {
            orientation = $0
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(item.name ?? "")
        .supportedOrientations(.allButUpsideDown)
        .overrideViewPreference(.unspecified)
        .preferredColorScheme(.none)
        .prefersHomeIndicatorAutoHidden(false)
    }
}
