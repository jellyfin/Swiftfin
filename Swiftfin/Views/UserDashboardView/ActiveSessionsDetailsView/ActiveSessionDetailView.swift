//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

struct ActiveSessionDetailView: View {
    @ObservedObject
    var viewModel: ActiveSessionsViewModel
    @State
    private var imageSources: [ImageSource] = []
    @State
    private var currentDate = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: Get Active Session

    private var session: SessionInfo {
        viewModel.sessions.first ?? SessionInfo()
    }

    // MARK: Body

    var body: some View {
        List {
            // Show the Now Playing Details if something is being streamed
            if let nowPlayingItem = session.nowPlayingItem {
                Section(L10n.media) {
                    nowPlayingSection(nowPlayingItem)
                }
                Section(L10n.progress) {
                    ActiveSessionsView.ProgressSection(
                        item: nowPlayingItem,
                        playState: session.playState,
                        transcodingInfo: session.transcodingInfo
                    )
                }
            }

            // Always show the Client Details
            Section("Device") {
                ActiveSessionsView.ClientSection(
                    client: session.client,
                    deviceName: session.deviceName,
                    applicationVersion: session.applicationVersion
                )
            }

            // Show the Stream Details if something is being streamed. Otherwise, show the Last Seen ticker.
            if let nowPlayingItem = session.nowPlayingItem {
                Section(L10n.streams) {
                    StreamSection(
                        nowPlayingItem: nowPlayingItem,
                        transcodingInfo: session.transcodingInfo,
                        playMethod: session.playState?.playMethod
                    )
                }
            } else if let lastActivityDate = session.lastActivityDate {
                Section("Last Seen") {
                    ActiveSessionsView.ConnectionSection(
                        lastActivityDate: lastActivityDate,
                        currentDate: currentDate,
                        prefixText: false
                    )
                }
            }

            // Always show the Transcode Reasons if present
            if let transcodeReasons = session.transcodingInfo?.transcodeReasons {
                Section("Reason(s)") {
                    TranscodeSection(transcodeReasons: transcodeReasons)
                }
            }
        }
        .navigationTitle(session.userName ?? L10n.unknown)
        .onAppear {
            viewModel.send(.refresh)
            setImageSources(session.nowPlayingItem)
        }
        .onChange(of: session.nowPlayingItem) { _ in
            setImageSources(session.nowPlayingItem)
        }
        .onReceive(timer) { _ in
            viewModel.send(.backgroundRefresh)
            currentDate = Date()
        }
    }

    // MARK: Progress Section

    @ViewBuilder
    private var progressSection: some View {
        let playbackPercentage = Double(session.playState?.positionTicks ?? 0) / Double(session.nowPlayingItem?.runTimeTicks ?? 0)

        ActiveSessionsView.TimelineSection(
            playbackPercentage: playbackPercentage,
            transcodingPercentage: (session.transcodingInfo?.completionPercentage ?? 0 / 100.0)
        )
    }

    // MARK: setImageSources

    private func setImageSources(_ nowPlayingItem: BaseItemDto?) {
        if let imageSource = nowPlayingItem?.cinematicImageSources().first {
            self.imageSources = [imageSource]
        } else {
            self.imageSources = []
        }
    }

    // MARK: Now Playing Section

    @ViewBuilder
    private func nowPlayingSection(_ item: BaseItemDto) -> some View {
        // Create a Cinematic poster for the Now Playing Item
        ImageView(item.cinematicImageSources().first!)
            .image { image in
                image
            }
            .placeholder { imageSource in
                ImageView.DefaultPlaceholderView(blurHash: imageSource.blurHash)
            }
            .failure {
                Color.accentColor
                    .opacity(0.75)
                    .overlay {
                        Text(item.name ?? L10n.unknown)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
            }
            .id(imageSources.hashValue)
            .scaledToFill()
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 4
                )
            )

        // Get the Name/Parent/Episode details for the Now Playing Item
        ActiveSessionsView.ContentSection(item: session.nowPlayingItem)

        // If available, get the Overview for the Now Playing Item
        if let overview = item.overview {
            Text(overview)
        }
    }
}
