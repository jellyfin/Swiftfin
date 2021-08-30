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

struct PortraitHeaderOverlayView: View {
    
    @EnvironmentObject private var viewModel: DetailItemViewModel
    @EnvironmentObject private var videoPlayerItem: VideoPlayerItem
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom, spacing: 12) {
                ImageView(src: viewModel.item.portraitHeaderViewURL(maxWidth: 130))
                    .frame(width: 130, height: 195)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 1) {
                    Spacer()
                    
                    Text(viewModel.item.name ?? "")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .offset(y: 5)
                    
                    Text(viewModel.item.getItemRuntime())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .padding(.top, 10)
                    
                    HStack {
                        if let productionYear = viewModel.item.productionYear {
                            Text(String(productionYear))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        if let officialRating = viewModel.item.officialRating {
                            Text(officialRating)
                                .font(.subheadline)
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
            
            if viewModel.item.itemType != .series {
                HStack {
                    
                    // MARK: Play
                    Button {
                        self.videoPlayerItem.itemToPlay = viewModel.item
                        self.videoPlayerItem.shouldShowPlayer = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                                .foregroundColor(Color.white)
                                .font(.system(size: 20))
                            Text(viewModel.item.getItemProgressString() == "" ? "Play" : viewModel.item.getItemProgressString())
                                .foregroundColor(Color.white)
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 130, height: 40)
                        .background(Color.jellyfinPurple)
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    // MARK: Favorite
                    Button {
                        viewModel.updateFavoriteState()
                    } label: {
                        if viewModel.isFavorited {
                            Image(systemName: "heart.fill")
                                .foregroundColor(Color(UIColor.systemRed))
                                .font(.system(size: 20))
                        } else {
                            Image(systemName: "heart")
                                .foregroundColor(Color.primary)
                                .font(.system(size: 20))
                        }
                    }
                    .disabled(viewModel.isLoading)
                    
                    // MARK: Watched
                    Button {
                        viewModel.updateWatchState()
                    } label: {
                        if viewModel.isWatched {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.jellyfinPurple)
                                .font(.system(size: 20))
                        } else {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(Color.primary)
                                .font(.system(size: 20))
                        }
                    }
                    .disabled(viewModel.isLoading)
                }.padding(.top, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? -189 : -64)
    }
}
