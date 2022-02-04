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
                            Text(DownloadManager.main.friendlyAvailableStorage ?? "--")
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
            
            if let downloadTracker = viewModel.itemViewModel.downloadTracker {
                DownloadItemProgressView(viewModel: viewModel, downloadTracker: downloadTracker)
                    .padding()
            } else {
                if viewModel.hasSpaceForItem {
                    PrimaryButtonView(title: "Download") {
                        viewModel.downloadItem()
                    }
                } else {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color(UIColor.secondarySystemFill))
                            .frame(maxWidth: 400, maxHeight: 50)
                            .frame(height: 50)
                            .cornerRadius(10)
                            .padding(.horizontal, 30)
                            .padding([.top, .bottom], 20)

                        Text("Unable to Download")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .bold()
                    }
                }
            }
        }
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
