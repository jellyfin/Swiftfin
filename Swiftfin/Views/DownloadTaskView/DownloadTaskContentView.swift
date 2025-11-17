//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

extension DownloadTaskView {

    struct ContentView: View {

        @Default(.accentColor)
        private var accentColor

        @Injected(\.downloadManager)
        private var downloadManager

        @Router
        private var router

        @ObservedObject
        var downloadTask: DownloadTask

        @State
        private var isPresentingVideoPlayerTypeError: Bool = false

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {

                VStack(alignment: .center) {
                    ImageView(downloadTask.item.landscapeImageSources(maxWidth: 600))
                        .frame(maxHeight: 300)
                        .aspectRatio(1.77, contentMode: .fill)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .posterShadow()

                    ShelfView(downloadTask: downloadTask)

                    // TODO: Break into subview
                    switch downloadTask.state {
                    case .ready, .cancelled:
                        Button("Download") {
                            downloadManager.download(task: downloadTask)
                        }
                        .frame(maxWidth: 300)
                        .frame(height: 50)
                    case let .downloading(progress):
                        HStack {
//                            CircularProgressView(progress: progress)
//                                .buttonStyle(.plain)
//                                .frame(width: 30, height: 30)

                            Text("\(Int(progress * 100))%")
                                .foregroundColor(.secondary)

                            Spacer()

                            Button {
                                downloadManager.cancel(task: downloadTask)
                            } label: {
                                Image(systemName: "stop.circle")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                    case let .error(error):
                        VStack {
                            Button(L10n.retry) {
                                downloadManager.download(task: downloadTask)
                            }
                            .frame(maxWidth: 300)
                            .frame(height: 50)

                            Text("Error: \(error.localizedDescription)")
                                .padding(.horizontal)
                        }
                    case .complete:
                        Button(L10n.play) {
                            if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                                router.dismiss()
//                                    router.route(to: .videoPlayer(manager: DownloadVideoPlayerManager(downloadTask: downloadTask)))
                            } else {
                                isPresentingVideoPlayerTypeError = true
                            }
                        }
                        .frame(maxWidth: 300)
                        .frame(height: 50)
                    }
                }

//                Text("Media Info")
//                    .font(.title2)
//                    .fontWeight(.semibold)
//                    .padding(.horizontal)
            }
            .alert(
                L10n.error,
                isPresented: $isPresentingVideoPlayerTypeError
            ) {
                Button {
                    isPresentingVideoPlayerTypeError = false
                } label: {
                    Text(L10n.dismiss)
                }
            } message: {
                Text("Downloaded items are only playable through the Swiftfin video player.")
            }
        }
    }
}

extension DownloadTaskView.ContentView {

    struct ShelfView: View {

        @ObservedObject
        var downloadTask: DownloadTask

        var body: some View {
            VStack(alignment: .center, spacing: 10) {

                if let seriesName = downloadTask.item.seriesName {
                    Text(seriesName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal)
                        .foregroundColor(.secondary)
                }

                Text(downloadTask.item.displayTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)

                DotHStack {
                    if downloadTask.item.type == .episode {
                        if let episodeLocation = downloadTask.item.episodeLocator {
                            Text(episodeLocation)
                        }
                    } else {
                        if let firstGenre = downloadTask.item.genres?.first {
                            Text(firstGenre)
                        }
                    }

                    if let productionYear = downloadTask.item.premiereDateYear {
                        Text(productionYear)
                    }

                    if let runtime = downloadTask.item.runTimeLabel {
                        Text(runtime)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
        }
    }
}
