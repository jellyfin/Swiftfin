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

struct ItemPortraitBodyView<PortraitHeaderView: View, PortraitStaticOverlayView: View>: View {
    
    @Binding private var videoIsLoading: Bool
    @EnvironmentObject private var viewModel: DetailItemViewModel
    @EnvironmentObject private var videoPlayerItem: VideoPlayerItem
    
    private let portraitHeaderView: (DetailItemViewModel) -> PortraitHeaderView
    private let portraitStaticOverlayView: (DetailItemViewModel) -> PortraitStaticOverlayView
    
    init(videoIsLoading: Binding<Bool>,
         portraitHeaderView: @escaping (DetailItemViewModel) -> PortraitHeaderView,
         portraitStaticOverlayView: @escaping (DetailItemViewModel) -> PortraitStaticOverlayView) {
        self._videoIsLoading = videoIsLoading
        self.portraitHeaderView = portraitHeaderView
        self.portraitStaticOverlayView = portraitStaticOverlayView
    }
    
    var body: some View {
        VStack(alignment: .leading) {
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
            
            // MARK: Body
            ParallaxHeaderScrollView(header: portraitHeaderView(viewModel),
                                     staticOverlayView: portraitStaticOverlayView(viewModel),
                                     overlayAlignment: .bottomLeading,
                                     headerHeight: UIDevice.current.userInterfaceIdiom == .pad ? 350 : UIScreen.main.bounds.width * 0.5625) {
                VStack {
                    Spacer()
                        .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 135 : 40)
                        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 54 : 24)
                    
                    // MARK: Overview
                    Text(viewModel.item.overview ?? "")
                        .font(.footnote)
                        .padding(.top, 3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 3)
                        .padding(.leading, 16)
                        .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                    
                    // MARK: Genres
                    PillHStackView(title: "Genres",
                                   items: viewModel.item.genreItems ?? []) { genre in
                        LibraryView(viewModel: .init(genre: genre), title: genre.title)
                    }
                    
                    // MARK: Studios
                    if let studios = viewModel.item.studios {
                        PillHStackView(title: "Studios",
                                       items: studios) { studio in
                            LibraryView(viewModel: .init(studio: studio), title: studio.name ?? "")
                        }
                    }
                    
                    // MARK: Cast
                    PortraitImageHStackView(items: viewModel.item.people?.filter({ $0.type == "Actor" }) ?? [],
                                            maxWidth: 150) {
                                    Text("Cast")
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                        .padding(.top, 3)
                                        .padding(.leading, 16)
                    } navigationView: { person in
                        LibraryView(viewModel: .init(person: person), title: person.title)
                    }

                    // MARK: More Like This
                    
                    
                    Spacer(minLength: 10)
                }
//                .introspectTabBarController { (UITabBarController) in
//                    UITabBarController.tabBar.isHidden = false
//                }
//                .navigationBarBackButtonHidden(false)
                .environmentObject(videoPlayerItem)
            }
        }
    }
}
