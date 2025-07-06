//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

struct DownloadListView: View {

    @ObservedObject
    var viewModel: DownloadListViewModel

    @Injected(\.networkMonitor)
    private var networkMonitor

    var body: some View {
        ZStack {
            if viewModel.items.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("No Downloads")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Download content to watch offline")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView(showsIndicators: false) {
                    if !networkMonitor.isConnected {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Offline Mode", systemImage: "wifi.slash")
                                .font(.headline)
                                .foregroundColor(.orange)

                            Text("You're viewing downloaded content")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top)
                    }

                    ForEach(viewModel.items) { item in
                        DownloadTaskRow(downloadTask: item)
                    }
                }
            }
        }
        .navigationTitle(L10n.downloads)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.refresh()
        }
    }
}

extension DownloadListView {

    struct DownloadTaskRow: View {

        @Router
        private var router

        let downloadTask: DownloadTask

        var body: some View {
            Button {
                router.route(to: .downloadTask(downloadTask: downloadTask))
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    ImageView(downloadTask.getImageURL(name: "Primary"))
                        .failure {
                            Rectangle()
                                .foregroundColor(.secondary.opacity(0.3))
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                }
                        }
                        .aspectRatio(2 / 3, contentMode: .fill)
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                        .clipped()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(downloadTask.item.displayTitle)
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if let overview = downloadTask.item.overview {
                            Text(overview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        if let runtime = downloadTask.item.runTimeLabel {
                            Label(runtime, systemImage: "clock")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Play button
                    Button {
                        let manager = DownloadVideoPlayerManager(downloadTask: downloadTask)
                        router.route(to: .videoPlayer(manager: manager))
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
}
