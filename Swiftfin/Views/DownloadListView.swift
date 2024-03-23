//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct DownloadListView: View {

    @ObservedObject
    var viewModel: DownloadListViewModel

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 400))], alignment: .center, spacing: 16) {
                ForEach(viewModel.items) { item in
                    DownloadTaskRow(downloadTask: item)
                }
            }
            .padding(20)
            .navigationTitle(L10n.downloads)
            .navigationBarTitleDisplayMode(.inline)
        }

        Spacer()
    }
}

extension DownloadListView {

    struct DownloadTaskRow: View {

        @EnvironmentObject
        private var mainCoordinator: MainCoordinator.Router

        @EnvironmentObject
        private var router: DownloadListCoordinator.Router

        let downloadTask: DownloadTask

        var body: some View {
//            VStack {
//                Text(downloadTask.item.displayTitle)
//                    .foregroundColor(.white)
//                    .fontWeight(.semibold)
//                    .multilineTextAlignment(.leading)
//
//                if downloadTask.item.type == .episode {
//                    Text(downloadTask.item.seriesName ?? "NO SERIES")
//                        .foregroundColor(.white)
//                        .multilineTextAlignment(.leading)
//                    Text(downloadTask.item.episodeLocator ?? "NO EPISODE")
//                        .foregroundColor(.white)
//                        .multilineTextAlignment(.leading)
//                }
//            }
//            .onTapGesture {
//                router.route(to: \.downloadTask, downloadTask)
//            }
//            .padding(20)
//            .background(Color.jellyfinPurple)
//            .cornerRadius(20)

            VStack(alignment: .leading, spacing: 10) {

                VStack(alignment: .center) {
                    ImageView(downloadTask.item.landscapePosterImageSources(maxWidth: 600, single: true))
                        .frame(maxHeight: 300)
                        .aspectRatio(1.77, contentMode: .fill)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .posterShadow()

                    DownloadTaskView.ContentView.ShelfView(downloadTask: downloadTask)

                    PrimaryButton(title: L10n.play)
                        .onSelect {
                            mainCoordinator.route(to: \.videoPlayer, DownloadVideoPlayerManager(downloadTask: downloadTask))
                        }
                        .frame(maxWidth: 300)
                        .frame(height: 50)
                }
            }
        }
    }
}
