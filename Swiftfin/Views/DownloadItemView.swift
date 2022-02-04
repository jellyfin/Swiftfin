//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Stinsen
import SwiftUI

struct DownloadItemView: View {
    
    @EnvironmentObject
    var downloadItemRouter: DownloadItemCoordinator.Router
    @ObservedObject
    var viewModel: DownloadItemViewModel
    
    @ViewBuilder
    private var queueDownloadView: some View {
        VStack {
            HStack(alignment: .top) {
                ImageView(src: viewModel.itemViewModel.item.portraitHeaderViewURL(maxWidth: 130))
                    .portraitPoster(width: 130)
                    .accessibilityIgnoresInvertColors()
                
                VStack(alignment: .leading, spacing: 5) {
                    
                    Text(viewModel.itemViewModel.getItemDisplayName())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let runtime = viewModel.itemViewModel.item.getItemRuntime() {
                        Text(runtime)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical)
                
                Spacer()
            }
            .padding(.bottom)
            
            VStack(alignment: .leading, spacing: 2) {
                
                L10n.file.text
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(viewModel.itemViewModel.selectedVideoPlayerViewModel?.filename ?? "--")
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.subheadline)
                    .foregroundColor(Color.secondary)
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom)
            
            VStack(alignment: .leading, spacing: 2) {
                
                Text("Estimated Storage")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(viewModel.itemViewModel.selectedVideoPlayerViewModel?.friendlyStorage ?? "--")
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.subheadline)
                    .foregroundColor(Color.secondary)
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            if let downloadTracker = viewModel.itemViewModel.downloadTracker {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Downloading")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f", viewModel.downloadProgress * 100)) %")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    LineProgressBar(value: $viewModel.downloadProgress)
                        .frame(height: 15)
                    
                    switch downloadTracker.state {
                    case .idle:
                        Button {
                            downloadTracker.start()
                        } label: {
                            Text("Start")
                        }
                    case .downloading:
                        Button {
                            downloadTracker.pause()
                        } label: {
                            Text("Pause")
                        }
                    case .paused:
                        Button {
                            downloadTracker.resume()
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
            } else {
                PrimaryButtonView(title: "Download") {
                    if let selectedVideoPlayerViewModel = viewModel.itemViewModel.selectedVideoPlayerViewModel {
                        do {
                            try DownloadManager.main.addDownload(playbackInfo: selectedVideoPlayerViewModel.response,
                                                             item: selectedVideoPlayerViewModel.item,
                                                             fileName: selectedVideoPlayerViewModel.filename ?? "None")
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    var body: some View {
        Group {
            if viewModel.itemViewModel.isDownloaded {
                Text("Downloaded")
            } else {
                queueDownloadView
            }
        }
            .navigationTitle("Download")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        downloadItemRouter.dismissCoordinator()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
    }
}
