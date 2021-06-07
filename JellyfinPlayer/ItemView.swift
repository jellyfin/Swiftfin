/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import Introspect
import JellyfinAPI

//good lord the environmental modifiers ;P

class VideoPlayerItem: ObservableObject {
    @Published var shouldShowPlayer: Bool = false;
    @Published var itemToPlay: BaseItemDto = BaseItemDto();
}

struct ItemView: View {
    private var item: BaseItemDto;
    @StateObject private var videoPlayerItem: VideoPlayerItem = VideoPlayerItem()
    
    @State private var isLoading: Bool = false; //This variable is only changed by the underlying VLC view.
    
    init(item: BaseItemDto) {
        self.item = item;
    }
    
    var body: some View {
        if(videoPlayerItem.shouldShowPlayer) {
            LoadingViewNoBlur(isShowing: $isLoading) {
                VLCPlayerWithControls(item: playback.itemToPlay, loadBinding: $isLoading, pBinding: _videoPlayerItem.projectedValue.shouldShowPlayer)
            }.navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .statusBar(hidden: true)
            .prefersHomeIndicatorAutoHidden(true)
            .preferredColorScheme(.dark)
            .edgesIgnoringSafeArea(.all)
            .overrideViewPreference(.unspecified)
            .supportedOrientations(.landscape)
        } else {
            Group {
                if(item.Type == "Movie") {
                    MovieItemView(item: self.item)
                } else if(item.Type == "Season") {
                    SeasonItemView(item: self.item)
                } else if(item.Type == "Series") {
                    SeriesItemView(item: self.item)
                } else if(item.Type == "Episode") {
                    EpisodeItemView(item: self.item)
                } else {
                    Text("Type: \(item.Type) not implemented yet :(")
                }
            }
            .introspectTabBarController { (UITabBarController) in
                UITabBarController.tabBar.isHidden = false
            }
            .navigationBarHidden(false)
            .navigationBarBackButtonHidden(false)
            .statusBar(hidden: false)
            .prefersHomeIndicatorAutoHidden(false)
            .preferredColorScheme(.none)
            .edgesIgnoringSafeArea([])
            .overrideViewPreference(.unspecified)
            .supportedOrientations(.allButUpsideDown)
            .environmentObject(playback)
        }
    }
}
