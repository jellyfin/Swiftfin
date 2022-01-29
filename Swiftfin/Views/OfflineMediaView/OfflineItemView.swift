//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct OfflineItemView: View {
    
    @EnvironmentObject
    var offlineItemRouter: OfflineItemCoordinator.Router
    
    let offlineItem: OfflineItem
    
    var body: some View {
        ScrollView {
            VStack {
                
                Group {
                    if let backdropImageURL = offlineItem.backdropImageURL {
                        ImageView(src: backdropImageURL )
                    } else {
                        Color.gray
                    }
                }
                .frame(width: 320, height: 180)
                .cornerRadius(5)
                
                VStack() {
                    Text(offlineItem.item.title)
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    if offlineItem.item.itemType == .episode {
                        Text(offlineItem.item.getEpisodeLocator() ?? "--")
                    }
                }
                
                Button {
                    let viewModel = offlineItem.item.createVideoPlayerViewModel(from: offlineItem.playbackInfo)[0]
                    viewModel.setNetworkType(.offline)
                    viewModel.injectCustomValues(startFromBeginning: true)
                    offlineItemRouter.route(to: \.videoPlayer, viewModel)
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                            .foregroundColor(Color.white)
                            .font(.system(size: 20))
                        L10n.play.text
                            .foregroundColor(Color.white)
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 300, height: 50)
                    .background(Color.jellyfinPurple)
                    .cornerRadius(10)
                }
                
                Button {
                    DownloadManager.main.deleteItem(offlineItem)
                    offlineItemRouter.dismissCoordinator()
                } label: {
                    Text("Delete")
                }
            }
            .padding()
        }
    }
}
