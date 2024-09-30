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
import SwiftUIIntrospect

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

            nowPlayingSection(nowPlayingItem)

            Section(L10n.progress) {
                ActiveDevicesView.ProgressSection(
                    item: nowPlayingItem,
                    playState: playState,
                    transcodingInfo: transcodingInfo
                )
            }

            Section(L10n.user) {
                if let userID = session.userID {
                    SettingsView.UserProfileRow(
                        user: .init(
                            id: userID,
                            name: session.userName
                        )
                    )
                }

                if let client {
                    TextPairView(leading: "Client", trailing: client)
                }

                if let deviceName {
                    TextPairView(leading: "Device", trailing: deviceName)
                }

                if let applicationVersion {
                    TextPairView(leading: "Version", trailing: applicationVersion)
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

    // MARK: Now Playing Section

    @ViewBuilder
    private func nowPlayingSection(_ item: BaseItemDto) -> some View {
        Section {
            HStack(alignment: .bottom, spacing: 12) {
                Group {
                    if session.nowPlayingItem?.type == .audio {
                        ZStack {
                            Color.clear

                            ImageView(session.nowPlayingItem?.squareImageSources(maxWidth: 60) ?? [])
                                .failure {
                                    SystemImageContentView(systemName: session.nowPlayingItem?.systemImage)
                                }
                        }
                        .squarePosterStyle()
                    } else {
                        ZStack {
                            Color.clear

                            ImageView(session.nowPlayingItem?.portraitImageSources(maxWidth: 60) ?? [])
                                .failure {
                                    SystemImageContentView(systemName: session.nowPlayingItem?.systemImage)
                                }
                        }
                        .posterStyle(.portrait)
                    }
                }
                .frame(width: 100)
                .accessibilityIgnoresInvertColors()

                if let item = session.nowPlayingItem {
                    ActiveDevicesView.ContentSection(item: item)
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowCornerRadius(0)
        .listRowInsets(.zero)
    }

    @ViewBuilder
    private func itemDescription(_ item: BaseItemDto) -> some View {
        if let itemOverview = item.overview {
            Section {
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
}

final class InsetsGroupedCell: UITableViewCell {

    override class var layerClass: AnyClass {
        InsetsGroupedLayer.self
    }
}

final class InsetsGroupedLayer: CALayer {

    override var cornerRadius: CGFloat {
        get { 16 }
        set {}
    }
}
