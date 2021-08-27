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
        VStack(alignment: .leading) {
            HStack(alignment: .bottom, spacing: 12) {
                ImageView(src: item.getPrimaryImage(maxWidth: 130))
                    .frame(width: 130, height: 195)
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
                    .padding(.top, 1)
                }
                .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 98 : 30)
            }
            HStack {
                // Play button
                Button {
                    ()
//                    self.playbackInfo.itemToPlay = item
//                    self.playbackInfo.shouldShowPlayer = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill").foregroundColor(Color.white).font(.system(size: 20))
                        Text(item.getItemProgressString() == "" ? "Play" : item.getItemProgressString())
                            .foregroundColor(Color.white).font(.callout).fontWeight(.semibold)
                    }
                    .frame(width: 130, height: 40)
                    .background(Color.jellyfinPurple)
                    .cornerRadius(10)
                }
                
                Spacer()
                
                Button {
                    print("Heart")
                } label: {
                    Image(systemName: "heart").foregroundColor(.primary)
                        .font(.system(size: 20))
                }
                
                Button {
                    print("Check")
                } label: {
                    Image(systemName: "checkmark.circle").foregroundColor(.primary)
                        .font(.system(size: 20))
                }
                    
                    
//                    Button {
//                        updateFavoriteState()
//                        ()
//                    } label: {
//                        if viewModel.isFavorited {
//                            Image(systemName: "heart.fill").foregroundColor(Color(UIColor.systemRed))
//                                .font(.system(size: 20))
//                        } else {
//                            Image(systemName: "heart").foregroundColor(Color.primary)
//                                .font(.system(size: 20))
//                        }
//                    }
//                    .disabled(viewModel.isLoading)
//                    Button {
//                        viewModel.updateWatchState()
//                        ()
//                    } label: {
//                        if viewModel.isWatched {
//                            Image(systemName: "checkmark.circle.fill").foregroundColor(Color.primary)
//                                .font(.system(size: 20))
//                        } else {
//                            Image(systemName: "checkmark.circle").foregroundColor(Color.primary)
//                                .font(.system(size: 20))
//                        }
//                    }
//                    .disabled(viewModel.isLoading)
//                }
            }.padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? -189 : -64)
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
            
            ParallaxHeaderScrollView(header: portraitHeaderView,
                                     staticOverlayView: portraitHeaderOverlayView,
                                     overlayAlignment: .bottomLeading,
                                     headerHeight: UIDevice.current.userInterfaceIdiom == .pad ? 350 : UIScreen.main.bounds
                                        .width * 0.5625) {
                VStack {
                    Spacer()
                        .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 135 : 40)
                        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 54 : 24)
                    
                    
                    
                    
                    
                    if item.type == "Movie" {
//                        MovieItemView(viewModel: .init(item: item))
                        Text("Movie")
                    } else if item.type == "Season" {
                        SeasonItemView(viewModel: .init(item: item))
                    } else if item.type == "Series" {
                        SeriesItemView(viewModel: .init(item: item))
                    } else if item.type == "Episode" {
                        EpisodeItemView(viewModel: .init(item: item))
                    } else {
                        Text("Type: \(item.type ?? "") not implemented yet :(")
                    }
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
