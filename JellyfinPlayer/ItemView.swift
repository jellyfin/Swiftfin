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

    var body: some View {
        VStack {
            NavigationLink(destination: LoadingViewNoBlur(isShowing: $videoIsLoading) { VLCPlayerWithControls(item: videoPlayerItem.itemToPlay, loadBinding: $videoIsLoading, pBinding: _videoPlayerItem.projectedValue.shouldShowPlayer)
                    .navigationBarHidden(true)
                    .navigationBarBackButtonHidden(true)
                    .statusBar(hidden: true)
                    .edgesIgnoringSafeArea(.all)
                    .prefersHomeIndicatorAutoHidden(true)
              }, isActive: $videoPlayerItem.shouldShowPlayer) {
                EmptyView()
            }
            VStack {
                if item.type == "Movie" {
                    MovieItemView(viewModel: .init(item: item))
                } else if item.type == "Season" {
                    SeasonItemView(viewModel: .init(item: item))
                } else if item.type == "Series" {
                    SeriesItemView(item: item)
                } else if item.type == "Episode" {
                    EpisodeItemView(viewModel: .init(item: item))
                } else {
                    Text("Type: \(item.type ?? "") not implemented yet :(")
                }
            }
            .introspectTabBarController { (UITabBarController) in
                UITabBarController.tabBar.isHidden = false
            }
            .navigationBarHidden(false)
            .navigationBarBackButtonHidden(false)
            .environmentObject(videoPlayerItem)
        }
    }
}
