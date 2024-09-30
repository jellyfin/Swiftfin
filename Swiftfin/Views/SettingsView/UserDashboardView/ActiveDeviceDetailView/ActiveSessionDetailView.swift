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

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @ObservedObject
    var viewModel: ActiveSessionsViewModel

    @State
    private var currentDate = Date()

    // MARK: - Timer

    private let timer = Timer.publish(every: 5, on: .main, in: .common)
        .autoconnect()

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
        .navigationTitle("Session")
        .onAppear {
            viewModel.send(.getSessions)
        }
        .onReceive(timer) { date in
            viewModel.send(.refreshSessions)
            currentDate = date
        }
    }

    // MARK: Create Idle Content View

    @ViewBuilder
    private func idleContent(client: String?, deviceName: String?, applicationVersion: String?, lastActivityDate: Date?) -> some View {
        List {
            Section(L10n.device) {
                ActiveDevicesView.ClientSection(
                    client: client,
                    deviceName: deviceName,
                    applicationVersion: applicationVersion
                )
            }

            // Show the the Last Seen Ticker (if possible) on Idle
            if let lastActivityDate = lastActivityDate {
                Section(L10n.lastSeen) {
                    ActiveDevicesView.ConnectionSection(
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
            Section(L10n.media) {
                nowPlayingSection(nowPlayingItem)
            }

            Section(L10n.progress) {
                ActiveDevicesView.ProgressSection(
                    item: nowPlayingItem,
                    playState: playState,
                    transcodingInfo: transcodingInfo
                )
            }

            Section(L10n.device) {
                if let client {
                    TextPairView(leading: "Client", trailing: client)
                }

                if let deviceName {
                    TextPairView(leading: "Device", trailing: deviceName)
                }

                if let applicationVersion {
                    TextPairView(leading: "Application Version", trailing: applicationVersion)
                }
            }

            Section(L10n.streams) {
                if let playMethod = playState.playMethod {
                    // TODO: localize instead of using raw value
                    TextPairView(leading: "Method", trailing: playMethod.rawValue)
                }

                StreamSection(
                    nowPlayingItem: nowPlayingItem,
                    transcodingInfo: transcodingInfo
                )
            }

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

//        ActiveDevicesView.TimelineSection(
//            playbackPercentage: playbackPercentage,
//            transcodingPercentage: (session.transcodingInfo?.completionPercentage ?? 0 / 100.0)
//        )
    }

    // MARK: Now Playing Section

    @ViewBuilder
    private func nowPlayingSection(_ item: BaseItemDto) -> some View {
//        ImageView(item.cinematicImageSources())
//            .failure {
//                Color.accentColor
//                    .opacity(0.75)
//                    .overlay {
//                        Text(item.name ?? L10n.unknown)
//                            .font(.headline)
//                            .foregroundColor(.primary)
//                    }
//            }

        // Get the Name/Parent/Episode details for the Now Playing Item
        ActiveDevicesView.ContentSection(item: session.nowPlayingItem)

        // If available, get the Overview for the Now Playing Item
        VStack(alignment: .leading, spacing: 10) {

            if let firstTagline = item.taglines?.first {
                Text(firstTagline)
                    .font(.body)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }

            if let itemOverview = item.overview {
                TruncatedText(itemOverview)
                    .onSeeMore {
                        router.route(to: \.itemOverviewView, item)
                    }
                    .seeMoreType(.view)
                    .font(.footnote)
                    .lineLimit(3)
            }
        }
    }
}
