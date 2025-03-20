//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct PlayButton: View {

        @Injected(\.logService)
        private var logger

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: ItemViewModel

        @FocusState
        private var isFocused: Bool

        // MARK: - Media Sources

        private var mediaSources: [MediaSourceInfo] {
            viewModel.playButtonItem?.mediaSources ?? []
        }

        // MARK: - Title

        private var title: String {
            if let seriesViewModel = viewModel as? SeriesItemViewModel {
                return seriesViewModel.playButtonItem?.seasonEpisodeLabel ?? L10n.play
            } else {
                return viewModel.playButtonItem?.playButtonLabel ?? L10n.play
            }
        }

        // MARK: - Subtitle

        private var subtitle: String? {
            if mediaSources.count > 1 {
                return viewModel.selectedMediaSource?.displayTitle
            } else {
                return nil
            }
        }

        // MARK: - Body

        var body: some View {
            HStack(spacing: 20) {
                Button {
                    if let playButtonItem = viewModel.playButtonItem, let selectedMediaSource = viewModel.selectedMediaSource {
                        router.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: playButtonItem, mediaSource: selectedMediaSource))
                    } else {
                        logger.error("No media source available")
                    }
                } label: {
                    ZStack {
                        if let subtitle, false {
                            VStack {
                                Spacer()
                                Text(subtitle)
                                    .lineLimit(1)
                                    .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.black)
                                    .fontWeight(.semibold)
                            }
                        }
                        HStack(spacing: 15) {
                            Image(systemName: "play.fill")
                                .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.black)
                                .font(.title3)

                            Text(title)
                                .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.black)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(width: mediaSources.count > 1 ? 280 : 400, height: 100)
                    .background {
                        if isFocused {
                            viewModel.playButtonItem == nil ? Color.secondarySystemFill : Color.white
                        } else {
                            Color.white
                                .opacity(0.5)
                        }
                    }
                    .cornerRadius(10)
                }
                .focused($isFocused)
                .buttonStyle(.card)
                //            .contextMenu {
                //                if viewModel.playButtonItem != nil, viewModel.item.userData?.playbackPositionTicks ?? 0 > 0 {
                //                    Button {
                //                        if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                //                            selectedVideoPlayerViewModel.injectCustomValues(startFromBeginning: true)
                //                            router.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
                //                        } else {
                //                            logger.error("Attempted to play item but no playback information available")
                //                        }
                //                    } label: {
                //                        Label(L10n.playFromBeginning, systemImage: "gobackward")
                //                    }
                //
                //                    Button(role: .cancel) {} label: {
                //                        L10n.cancel.text
                //                    }
                //                }
                //            }

                if mediaSources.count > 1 {
                    VersionMenu(viewModel: viewModel, mediaSources: mediaSources)
                        .frame(width: 100, height: 100)
                }
            }
        }
    }
}
