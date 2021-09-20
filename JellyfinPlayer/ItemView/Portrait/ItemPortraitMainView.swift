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

struct ItemPortraitMainView: View {
    
    @Binding private var videoIsLoading: Bool
    @EnvironmentObject private var viewModel: ItemViewModel
    @EnvironmentObject private var videoPlayerItem: VideoPlayerItem
    
    init(videoIsLoading: Binding<Bool>) {
        self._videoIsLoading = videoIsLoading
    }
    
    // MARK: portraitHeaderView
    var portraitHeaderView: some View {
        ImageView(src: viewModel.item.getBackdropImage(maxWidth: Int(UIScreen.main.bounds.width)),
                  bh: viewModel.item.getBackdropImageBlurHash())
            .opacity(0.4)
            .blur(radius: 2.0)
    }
    
    // MARK: portraitStaticOverlayView
    var portraitStaticOverlayView: some View {
        PortraitHeaderOverlayView()
            .environmentObject(viewModel)
    }
    
    // MARK: body
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
            
            // MARK: ParallaxScrollView
            ParallaxHeaderScrollView(header: portraitHeaderView,
                                     staticOverlayView: portraitStaticOverlayView,
                                     overlayAlignment: .bottomLeading,
                                     headerHeight: UIScreen.main.bounds.width * 0.5625) {
                
                VStack {
                    Spacer()
                        .frame(height: 70)
                    
                    if let episodeViewModel = viewModel as? SeasonItemViewModel {
                        Spacer()
                        CardVStackView(items: episodeViewModel.episodes)
                            .padding(.top, 5)
                    } else {
                        ItemViewBody()
                            .environmentObject(viewModel)
                    }
                }
            }
        }
    }
}
