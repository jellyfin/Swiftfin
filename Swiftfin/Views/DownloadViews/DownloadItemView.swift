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
    private var bottomView: some View {
        if viewModel.itemViewModel.isDownloaded {
            VStack(spacing: 15) {
                Button {
                    if let videoPlayerViewModel = viewModel.offlineVideoPlayerViewModel() {
                        videoPlayerViewModel.setNetworkType(.offline)
                        videoPlayerViewModel.injectCustomValues(startFromBeginning: true)
                        downloadItemRouter.route(to: \.videoPlayer, videoPlayerViewModel)
                    }
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color.jellyfinPurple)
                            .frame(maxWidth: 400, maxHeight: 50)
                            .frame(height: 50)
                            .cornerRadius(10)
                            .padding(.horizontal, 30)

                        L10n.play.text
                            .foregroundColor(Color.white)
                            .bold()
                    }
                }
                
                Button {
                    viewModel.deleteItem()
                    downloadItemRouter.dismissCoordinator()
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color.red.opacity(0.1))
                            .frame(maxWidth: 400, maxHeight: 50)
                            .frame(height: 50)
                            .cornerRadius(10)
                            .padding(.horizontal, 30)

                        Text("Delete")
                            .foregroundColor(Color.red)
                            .bold()
                    }
                }
            }
        } else {
            if let downloadTracker = viewModel.downloadTracker {
                DownloadItemProgressView(viewModel: viewModel, downloadTracker: downloadTracker)
                    .padding()
            } else {
                Button {
                    viewModel.downloadItem()
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color.jellyfinPurple)
                            .frame(maxWidth: 400, maxHeight: 50)
                            .frame(height: 50)
                            .cornerRadius(10)
                            .padding(.horizontal, 30)
                            .padding([.top, .bottom], 20)

                        Text("Download")
                            .foregroundColor(Color.white)
                            .bold()
                    }
                }
            }
        }
    }
    
    var body: some View {
        Group {
            VStack {
                ScrollView {
                    VStack {
                        HStack(alignment: .bottom, spacing: 12) {
                            ImageView(viewModel.itemViewModel.item.portraitHeaderViewURL(maxWidth: 130))
                                .portraitPoster(width: 130)
                                .accessibilityIgnoresInvertColors()
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Spacer()
                                
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
                        .fixedSize(horizontal: false, vertical: true)
                        
                        VStack(spacing: 15) {
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
                            
                            VStack(alignment: .leading, spacing: 2) {
                                
                                Text("Download Size")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text(viewModel.itemViewModel.selectedVideoPlayerViewModel?.friendlyStorage ?? "--")
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(.subheadline)
                                    .foregroundColor(Color.secondary)
                                
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                
                                Text("Available Storage")
                                    .font(.title3)
                                    .fontWeight(.semibold)
//                                Text(DownloadManager.main.friendlyAvailableStorage ?? "--")
                                Text("STORAGE")
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(.subheadline)
                                    .foregroundColor(Color.secondary)
                                
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                
                bottomView
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
