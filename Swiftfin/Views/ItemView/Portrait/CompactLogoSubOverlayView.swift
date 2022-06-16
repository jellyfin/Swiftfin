//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct CompactLogoSubOverlayView: View {
    
    @EnvironmentObject
    var itemRouter: ItemCoordinator.Router
    @ObservedObject
    private var viewModel: ItemViewModel
    
    init(viewModel: ItemViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {

                if let firstGenre = viewModel.item.genres?.first {
                    Text(firstGenre)

                    Circle()
                        .frame(width: 2, height: 2)
                        .padding(.horizontal, 1)
                }

                if let premiereYear = viewModel.item.premiereDateYear {
                    Text(String(premiereYear))

                    Circle()
                        .frame(width: 2, height: 2)
                        .padding(.horizontal, 1)
                }

                if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.getItemRuntime() {
                    Text(runtime)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            HStack {
                if let officialRating = viewModel.item.officialRating {
                    Text(officialRating)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                        .overlay(RoundedRectangle(cornerRadius: 2)
                            .stroke(Color(UIColor.lightGray), lineWidth: 1))
                }

                if let selectedPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                    if selectedPlayerViewModel.item.isHD ?? false {
                        Text("HD")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                            .hidden()
                            .background {
                                Color(UIColor.lightGray)
                                    .cornerRadius(2)
                                    .inverseMask(
                                        Group {
                                            Text("HD")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                        }
                                    )
                            }
                    }
                    
    //                    if selectedPlayerViewModel.item.audio == ProgramAudio.atmos {
                        Image("dolby.atmos")
    //                            .font(.body)
    //                    }
                    
                    if selectedPlayerViewModel.audioStreams.contains(where: { $0.channelLayout == "5.1" }) {
                        Text("5.1")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                            .hidden()
                            .background {
                                Color(UIColor.lightGray)
                                    .cornerRadius(2)
                                    .inverseMask(
                                        Group {
                                            Text("5.1")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                        }
                                    )
                            }
                    }
                    
                    if selectedPlayerViewModel.audioStreams.contains(where: { $0.channelLayout == "7.1" }) {
                        Text("7.1")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                            .hidden()
                            .background {
                                Color(UIColor.lightGray)
                                    .cornerRadius(2)
                                    .inverseMask(
                                        Group {
                                            Text("7.1")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                        }
                                    )
                            }
                    }
                    
                    if selectedPlayerViewModel.videoStream.videoRange == "HDR"  {
                        Text("HDR")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                            .hidden()
                            .background {
                                Color(UIColor.lightGray)
                                    .cornerRadius(2)
                                    .inverseMask(
                                        Group {
                                            Text("HDR")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                        }
                                    )
                            }
                    }
                    
                    if !selectedPlayerViewModel.subtitleStreams.isEmpty {
                        Text("CC")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                            .overlay(RoundedRectangle(cornerRadius: 2)
                                .stroke(Color(UIColor.lightGray), lineWidth: 1))
                    }
                }
            }
            .foregroundColor(.secondary)
            
            Button {
                if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                    itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
                } else {
                    LogManager.log.error("Attempted to play item but no playback information available")
                }
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondarySystemFill) : Color.jellyfinPurple)
                        .frame(maxWidth: 300, maxHeight: 50)
                        .frame(height: 50)
                        .cornerRadius(10)

                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                        Text(viewModel.playButtonText())
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.white)
                }
            }
            .contextMenu {
                if viewModel.playButtonItem != nil, viewModel.item.userData?.playbackPositionTicks ?? 0 > 0 {
                    Button {
                        if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                            selectedVideoPlayerViewModel.injectCustomValues(startFromBeginning: true)
                            itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
                        } else {
                            LogManager.log.error("Attempted to play item but no playback information available")
                        }
                    } label: {
                        Label(L10n.playFromBeginning, systemImage: "gobackward")
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}
