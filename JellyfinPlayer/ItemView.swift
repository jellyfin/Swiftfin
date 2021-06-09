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
    @EnvironmentObject private var globalData: GlobalData
    
    @State private var fullItem: BaseItemDto = BaseItemDto();
    private var item: BaseItemDto;
    
    @StateObject private var videoPlayerItem: VideoPlayerItem = VideoPlayerItem()
    @State private var videoIsLoading: Bool = false; //This variable is only changed by the underlying VLC view.
    @State private var isLoading: Bool = false;
    @State private var viewDidLoad: Bool = false;
    
    init(item: BaseItemDto) {
        self.item = item
    }
    
    func onAppear() {
        if(viewDidLoad) {
            return
        }
        
        if(item.type == "Movie" || item.type == "Episode") {
            isLoading = true;
            UserLibraryAPI.getItem(userId: globalData.user.user_id!, itemId: item.id!)
                .sink(receiveCompletion: { completion in
                    HandleAPIRequestCompletion(globalData: globalData, completion: completion)
                }, receiveValue: { response in
                    isLoading = false
                    viewDidLoad = true
                    fullItem = response
                })
                .store(in: &globalData.pendingAPIRequests)
        } else {
            viewDidLoad = true
        }
    }
    
    var body: some View {
        VStack {
            if(videoPlayerItem.shouldShowPlayer) {
                LoadingViewNoBlur(isShowing: $videoIsLoading) {
                    VLCPlayerWithControls(item: videoPlayerItem.itemToPlay, loadBinding: $videoIsLoading, pBinding: _videoPlayerItem.projectedValue.shouldShowPlayer)
                }.navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
                .statusBar(hidden: true)
                .prefersHomeIndicatorAutoHidden(true)
                .preferredColorScheme(.dark)
                .edgesIgnoringSafeArea(.all)
                .overrideViewPreference(.unspecified)
                .supportedOrientations(.landscape)
            } else {
                if(isLoading) {
                    ProgressView()
                } else {
                    VStack {
                        if(item.type == "Movie") {
                            MovieItemView(item: fullItem)
                        } else if(item.type == "Season") {
                            EmptyView()
                            SeasonItemView(item: item)
                        } else if(item.type == "Series") {
                            SeriesItemView(item: item)
                        } else if(item.type == "Episode") {
                            EmptyView()
                            //EpisodeItemView(item: fullItem)
                        } else {
                            Text("Type: \(fullItem.type ?? "") not implemented yet :(")
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
                    .environmentObject(videoPlayerItem)
                }
            }
        }
        .onAppear(perform: onAppear)
    }
}
