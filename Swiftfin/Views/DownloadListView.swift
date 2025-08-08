//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct DownloadListView: View {

    @ObservedObject
    var viewModel: DownloadListViewModel

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 72))
                .foregroundColor(.secondary)

            Text("No Downloads")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Download content to watch offline")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            /* TODO:
             if !networkMonitor.isConnected {
                 OfflineBanner(type: .offline, showDescription: true)
             } else if isServerUnreachable {
                 OfflineBanner(type: .serverUnreachable, showDescription: true)
             }
              */
        }
        .padding()
    }

    var body: some View {
        NavigationView {
            emptyView
        }
        .navigationTitle(L10n.downloads)
        .navigationBarTitleDisplayMode(.large)
    }
}
