/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import Introspect
import JellyfinAPI

class VideoPlayerItem: ObservableObject {
    @Published var shouldShowPlayer: Bool = false
    @Published var itemToPlay: BaseItemDto = BaseItemDto()
}

struct ItemView: View {
    private var item: BaseItemDto

    @StateObject private var videoPlayerItem: VideoPlayerItem = VideoPlayerItem()
    @State private var videoIsLoading: Bool = false; // This variable is only changed by the underlying VLC view.
    @State private var isLoading: Bool = false
    @State private var viewDidLoad: Bool = false

    init(item: BaseItemDto) {
        self.item = item
    }
    
    var portraitHeaderView: some View {
        ImageView(src: item.getBackdropImage(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 622 : Int(UIScreen.main.bounds.width)),
                  bh: item.getBackdropImageBlurHash())
            .opacity(0.4)
            .blur(radius: 2.0)
    }
    
    var portraitHeaderOverlayView: some View {
        PortraitHeaderOverlayView(item: item)
    }

    var body: some View {
        VStack {
            NavigationLink(destination: LoadingViewNoBlur(isShowing: $videoIsLoading) {
                VLCPlayerWithControls(item: videoPlayerItem.itemToPlay,
                                      loadBinding: $videoIsLoading,
                                      pBinding: _videoPlayerItem.projectedValue.shouldShowPlayer)
                    .navigationBarHidden(true)
                    .navigationBarBackButtonHidden(true)
                    .statusBar(hidden: true)
                    .edgesIgnoringSafeArea(.all)
                    .prefersHomeIndicatorAutoHidden(true)
            }, isActive: $videoPlayerItem.shouldShowPlayer) {
                EmptyView()
            }
            
            ParallaxHeaderScrollView(header: portraitHeaderView,
                                     staticOverlayView: portraitHeaderOverlayView,
                                     overlayAlignment: .bottomLeading,
                                     headerHeight: UIDevice.current.userInterfaceIdiom == .pad ? 350 : UIScreen.main.bounds.width * 0.5625) {
                VStack {
                    Spacer()
                        .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 135 : 40)
                        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 54 : 24)
                    
                    // MARK: Overview
                    Text(item.overview ?? "")
                        .font(.footnote)
                        .padding(.top, 3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 3)
                        .padding(.leading, 16)
                        .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                    
                    // MARK: Genres
                    PillHStackView(title: "Genres", items: item.genreItems ?? []) { genre in
                        LibraryView(viewModel: .init(genre: genre), title: genre.title)
                    }
                    
                    // MARK: Studios
                    if !(item.studios ?? []).isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                Text("Studios:").font(.callout).fontWeight(.semibold)
                                ForEach(item.studios!, id: \.id) { studio in
                                    NavigationLink(destination: LazyView {
                                        LibraryView(viewModel: .init(studio: studio), title: studio.name ?? "")
                                    }) {
                                        Text(studio.name ?? "").font(.footnote)
                                    }
                                }
                            }
                            .padding(.leading, 16)
                            .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                        }
                    }
                    
                    // MARK: Cast
                    PortraitImageHStackView(title: "Cast",
                                            items: item.people!,
                                            maxWidth: 150) { person in
                        LibraryView(viewModel: .init(person: person), title: person.title)
                    }
                    
                    // MARK: More Like This
                    
                }
                .introspectTabBarController { (UITabBarController) in
                    UITabBarController.tabBar.isHidden = false
                }
                .navigationBarBackButtonHidden(false)
                .environmentObject(videoPlayerItem)
            }
            .navigationBarHidden(false)
        }
    }
}
