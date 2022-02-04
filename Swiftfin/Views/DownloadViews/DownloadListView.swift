//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct DownloadListView: View {
    
    @EnvironmentObject
    var downloadListRouter: DownloadListCoordinator.Router
    @ObservedObject
    var viewModel: DownloadListViewModel
    
    @ViewBuilder
    private var downloadingView: some View {
        Text("Downloading")
            .font(.title2)
            .fontWeight(.bold)
            .accessibility(addTraits: [.isHeader])
        
        ForEach(viewModel.downloadingItems, id: \.self) { download in
            DownloadTrackerRow(offlineItem: download) { offlineItem in
                downloadListRouter.route(to: \.downloadItem, ItemViewModel(item: offlineItem.item))
            }
        }
    }
    
    @ViewBuilder
    private var offlineItemsView: some View {
        Text("Downloaded")
            .font(.title2)
            .fontWeight(.bold)
            .accessibility(addTraits: [.isHeader])
        
        ForEach(viewModel.offlineItems, id: \.self) { download in
            DownloadTrackerRow(offlineItem: download) { offlineItem in
                downloadListRouter.route(to: \.downloadItem, ItemViewModel(item: offlineItem.item))
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                
                if !viewModel.downloadingItems.isEmpty {
                    downloadingView
                }
                
                if !viewModel.offlineItems.isEmpty {
                    offlineItemsView
                }
            }
            .padding()
        }
        .navigationTitle("Downloads")
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
    }
}
