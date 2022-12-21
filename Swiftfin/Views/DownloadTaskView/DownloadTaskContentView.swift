//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

extension DownloadTaskView {
    
    struct ContentView: View {
        
        @Injected(Container.downloadManager)
        private var downloadManager
        
        @ObservedObject
        var downloadTask: DownloadTask
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                
                VStack(alignment: .center) {
                    ImageView(downloadTask.item.landscapePosterImageSources(maxWidth: 600, single: true))
                        .frame(maxHeight: 300)
                        .aspectRatio(1.77, contentMode: .fill)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .posterShadow()
                    
                    ShelfView(downloadTask: downloadTask)
                }
                
                if case DownloadTask.State.ready = downloadTask.state {
                    PrimaryButton(title: "Download") {
                        downloadManager.download(task: downloadTask)
                    }
                } else if case let DownloadTask.State.downloading(progress) = downloadTask.state {
                    HStack {
                        CircularProgressView(progress: progress)
                            .buttonStyle(.plain)
                            .frame(width: 30, height: 30)
                        
                        Spacer()
                        
                        Button {
                            print("should cancel")
                        } label: {
                            Image(systemName: "stop.circle")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Text("something else")
                }
                
                Text("Media Info")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                
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
                        if let productionYear = downloadTask.item.productionYear {
                            Text(String(productionYear))
                        }
                    }

                    if let productionYear = downloadTask.item.premiereDateYear {
                        Text(productionYear)
                    }

                    if let runtime = downloadTask.item.getItemRuntime() {
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
