//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct DownloadListView: View {
    
    @State var downloads: [DownloadTracker] = []
    
    var body: some View {
        ScrollView {
            
            Button {
                let _ = DownloadManager.main.getOfflineItems()
            } label: {
                Text("Try get offline items")
            }
            
            Text("Storage Used: \(DownloadManager.main.totalStorageUsed)")
            
            VStack {
                ForEach(downloads, id: \.self) { download in
                    DownloadTrackerRow(tracker: download)
                }
            }
        }
        .onAppear {
            downloads = Array(DownloadManager.main.trackers)
        }
    }
}

struct DownloadTrackerRow: View {
    
    @ObservedObject var tracker: DownloadTracker
    
    var body: some View {
        HStack {
            
            Color.gray
                .frame(width: 100, height: 80)
            
            VStack(alignment: .leading) {
                Text(tracker.item.title)
                    .fontWeight(.medium)
                
                if tracker.item.itemType == .episode {
                    Text(tracker.item.getEpisodeLocator() ?? "--")
                        .font(.subheadline)
                }
                
                Spacer()
                
                HStack {
                    switch tracker.state {
                    case .idle:
                        Button {
                            tracker.start()
                        } label: {
                            Text("Start")
                        }
                    case .downloading:
                        Button {
                            tracker.pause()
                        } label: {
                            Text("Pause")
                        }
                        
                        Text("\(tracker.progress * 100)")
                    case .paused:
                        Button {
                            tracker.resume()
                        } label: {
                            Text("Resume")
                        }
                    case .cancelled:
                        Text("Cancelled")
                            .foregroundColor(.red)
                    case .done:
                        Text("Complete")
                    case .error:
                        Text("Error")
                            .foregroundColor(.red)
                    }
                }
                .font(.subheadline)
            }
            .padding(.vertical, 2)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 24))
        }
        .frame(height: 80)
        .padding(.horizontal)
    }
}
