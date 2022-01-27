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
            
            Text("Storage Used: \(DownloadManager.main.totalStorageUsed)")
            
            VStack {
                ForEach(downloads, id: \.self) { download in
                    DownloadRow(tracker: download)
                }
            }
        }
        .onAppear {
            downloads = Array(DownloadManager.main.trackers)
        }
    }
}

struct DownloadRow: View {
    
    @ObservedObject var tracker: DownloadTracker
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(tracker.item.title)
                
                Text("\(tracker.progress)")
            }
            
            Spacer()
            
            Button {
                tracker.start()
            } label: {
                Text("Start")
            }
            
            Button {
                tracker.pause()
            } label: {
                Text("Pause")
            }
            
            Button {
                tracker.resume()
            } label: {
                Text("Resume")
            }
        }
    }
}
