/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import Introspect

class ItemPlayback: ObservableObject {
    @Published var shouldPlay: Bool = false;
    @Published var itemToPlay: DetailItem = DetailItem();
}

struct ItemView: View {
    var item: ResumeItem;
    @StateObject private var playback: ItemPlayback = ItemPlayback()
    @State private var shouldShowLoadingView: Bool = false;
    
    init(item: ResumeItem) {
        self.item = item;
    }
    
    var body: some View {
        if(playback.shouldPlay) {
            LoadingViewNoBlur(isShowing: $shouldShowLoadingView) {
                VLCPlayerWithControls(item: playback.itemToPlay, loadBinding: $shouldShowLoadingView, pBinding: _playback.projectedValue.shouldPlay)
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
