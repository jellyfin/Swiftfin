//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct DownloadListView: View {
    
    @State
    var downloads: [OfflineItem] = []
    
    var body: some View {
        ScrollView {
            
            VStack {
                ForEach(downloads, id: \.self) { download in
                    DownloadTrackerRow(offlineItem: download) { item in
                        // TODO: Deeplink to online item
                    }
                }
            }
        }
        .onAppear {
            downloads = DownloadManager.main.offlineItems.sorted(by: { $0.downloadDate < $1.downloadDate })
        }
    }
}

struct DownloadTrackerRow<ItemType: OfflineItem>: View {
    
    let offlineItem: ItemType
    let selectedAction: (ItemType) -> Void
    
    var body: some View {
        Button {
            selectedAction(offlineItem)
        } label: {
            HStack {
                if let backdropImageURL = offlineItem.backdropImageURL {
                    ImageView(backdropImageURL)
                        .frame(width: 130, height: 100)
                        .cornerRadius(5)
                } else {
                    Color.gray
                        .frame(width: 130, height: 100)
                        .cornerRadius(5)
                }
                
                VStack(alignment: .leading) {
                    Text(offlineItem.item.title)
                        .fontWeight(.medium)
                        .foregroundColor(Color(UIColor.label))
                    
                    if offlineItem.item.itemType == .episode {
                        Text(offlineItem.item.getEpisodeLocator() ?? "--")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    
                    Spacer()
                    
                    Text(offlineItem.storage)
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .padding(.vertical, 2)
                
                Spacer()
            }
        }
        .padding()
    }
}
