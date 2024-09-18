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

struct ActiveDeviceDetailView: View {
    @ObservedObject
    var viewModel: ActiveSessionsViewModel
    @State
    private var imageSources: [ImageSource] = []
    @State
    private var currentDate = Date()

    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    // MARK: Get Active Session

    private var session: SessionInfo {
        viewModel.sessions.first ?? SessionInfo()
    }

    // MARK: Body

    var body: some View {
        Group {
            if let nowPlayingItem = session.nowPlayingItem, let playState = session.playState {
                sessionContent(
                    client: session.client,
                    deviceName: session.deviceName,
                    applicationVersion: session.applicationVersion,
                    nowPlayingItem: nowPlayingItem,
                    playState: playState,
                    transcodingInfo: session.transcodingInfo
                )
            } else {
                idleContent(
                    client: session.client,
                    deviceName: session.deviceName,
                    applicationVersion: session.applicationVersion,
                    lastActivityDate: session.lastActivityDate
                )
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
        .animation(.spring(), value: session.nowPlayingItem != nil)
    }

    // MARK: Create Idle Content View

    @ViewBuilder
    private func idleContent(client: String?, deviceName: String?, applicationVersion: String?, lastActivityDate: Date?) -> some View {
        List {
            // Always show the Client Details
            Section(L10n.device) {
                UserDashboardView.ClientSection(
                    client: client,
                    deviceName: deviceName,
                    applicationVersion: applicationVersion
                )
            }

            // Show the the Last Seen Ticker (if possible) on Idle
            if let lastActivityDate = lastActivityDate {
                Section(L10n.lastSeen) {
                    UserDashboardView.ConnectionSection(
                        lastActivityDate: lastActivityDate,
                        currentDate: currentDate,
                        prefixText: false
                    )
                }
            }
        }
    }

    // MARK: Create Session Content View

    @ViewBuilder
    private func sessionContent(
        client: String?,
        deviceName: String?,
        applicationVersion: String?,
        nowPlayingItem: BaseItemDto,
        playState: PlayerStateInfo,
        transcodingInfo: TranscodingInfo?
    ) -> some View {
        List {
            // Show the Now Playing Details if something is being streamed
            Section(L10n.media) {
                nowPlayingSection(nowPlayingItem)
            }

            // Show the Now Playing Progress if something is being streamed
            Section(L10n.progress) {
                UserDashboardView.ProgressSection(
                    item: nowPlayingItem,
                    playState: playState,
                    transcodingInfo: transcodingInfo
                )
            }

            // Always show the Client Details
            Section(L10n.device) {
                UserDashboardView.ClientSection(
                    client: client,
                    deviceName: deviceName,
                    applicationVersion: applicationVersion
                )
            }

            // Show the Stream Details if something is being streamed. Otherwise, show the Last Seen ticker.
            Section(L10n.streams) {
                StreamSection(
                    nowPlayingItem: nowPlayingItem,
                    transcodingInfo: transcodingInfo,
                    playMethod: playState.playMethod
                )
            }

            // Always show the Transcode Reasons if present
            if let transcodeReasons = transcodingInfo?.transcodeReasons {
                Section(L10n.transcodeReasons) {
                    TranscodeSection(transcodeReasons: transcodeReasons)
                }
            }
        }
    }

    // MARK: Progress Section

    @ViewBuilder
    private var progressSection: some View {
        let playbackPercentage = Double(session.playState?.positionTicks ?? 0) / Double(session.nowPlayingItem?.runTimeTicks ?? 0)

        UserDashboardView.TimelineSection(
            playbackPercentage: playbackPercentage,
            transcodingPercentage: (session.transcodingInfo?.completionPercentage ?? 0 / 100.0)
        )
    }

    // MARK: setImageSources

    private func setImageSources(_ nowPlayingItem: BaseItemDto?) {
        if let imageSource = nowPlayingItem?.cinematicImageSources().first {
            imageSources = [imageSource]
        } else {
            imageSources = []
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
        UserDashboardView.ContentSection(item: session.nowPlayingItem)

        // If available, get the Overview for the Now Playing Item
        if let firstTagline = item.taglines?.first {
            Text(firstTagline)
                .font(.body)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }

        if let itemOverview = item.overview {
            TruncatedText(itemOverview)
                .lineLimit(3)
        } else {
            L10n.noOverviewAvailable.text
        }
    }
}
