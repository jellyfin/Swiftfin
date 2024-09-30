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
    var box: BindingBox<SessionInfo?>

    @State
    private var currentDate: Date = .now

    private let timer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()

    // MARK: Create Idle Content View

    @ViewBuilder
    private func idleContent(session: SessionInfo) -> some View {
        List {
            Section(L10n.user) {
                if let userID = session.userID {
                    SettingsView.UserProfileRow(
                        user: .init(
                            id: userID,
                            name: session.userName
                        )
                    )
                }

                if let client = session.client {
                    TextPairView(leading: "Client", trailing: client)
                }

                if let device = session.deviceName {
                    TextPairView(leading: "Device", trailing: device)
                }

                if let applicationVersion = session.applicationVersion {
                    TextPairView(leading: "Version", trailing: applicationVersion)
                }

                // TODO: update not working?
                if let lastActivityDate = session.lastActivityDate {
                    TextPairView(
                        "Last seen",
                        value: Text(lastActivityDate, format: .relative(presentation: .numeric, unitsStyle: .narrow))
                    )
                    .id(currentDate)
                    .monospacedDigit()
                }
            }
        }
    }

    // MARK: Create Session Content View

    @ViewBuilder
    private func sessionContent(
        session: SessionInfo,
        nowPlayingItem: BaseItemDto,
        playState: PlayerStateInfo
    ) -> some View {
        List {

            nowPlayingSection(item: nowPlayingItem)

            Section(L10n.progress) {
                ActiveDevicesView.ProgressSection(
                    item: nowPlayingItem,
                    playState: playState,
                    transcodingInfo: session.transcodingInfo
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

                if let client = session.client {
                    TextPairView(leading: "Client", trailing: client)
                }

                if let device = session.deviceName {
                    TextPairView(leading: "Device", trailing: device)
                }

                if let applicationVersion = session.applicationVersion {
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
                    transcodingInfo: session.transcodingInfo
                )
            }

            if let transcodeReasons = session.transcodingInfo?.transcodeReasons {
                Section(L10n.transcodeReasons) {
                    TranscodeSection(transcodeReasons: transcodeReasons)
                }
            }
        }
    }

    // MARK: Now Playing Section

    @ViewBuilder
    private func nowPlayingSection(item: BaseItemDto) -> some View {
        Section {
            HStack(alignment: .bottom, spacing: 12) {
                Group {
                    if item.type == .audio {
                        ZStack {
                            Color.clear

                            ImageView(item.squareImageSources(maxWidth: 60))
                                .failure {
                                    SystemImageContentView(systemName: item.systemImage)
                                }
                        }
                        .squarePosterStyle()
                    } else {
                        ZStack {
                            Color.clear

                            ImageView(item.portraitImageSources(maxWidth: 60))
                                .failure {
                                    SystemImageContentView(systemName: item.systemImage)
                                }
                        }
                        .posterStyle(.portrait)
                    }
                }
                .frame(width: 100)
                .accessibilityIgnoresInvertColors()

                ActiveDevicesView.ContentSection(item: item)
            }
        }
        .listRowBackground(Color.clear)
        .listRowCornerRadius(0)
        .listRowInsets(.zero)
    }

    var body: some View {
        ZStack {
            if let session = box.value {
                if let nowPlayingItem = session.nowPlayingItem, let playState = session.playState {
                    sessionContent(
                        session: session,
                        nowPlayingItem: nowPlayingItem,
                        playState: playState
                    )
                } else {
                    idleContent(session: session)
                }
            } else {
                Text("No session")
            }
        }
        .animation(.linear(duration: 0.2), value: box.value)
        .navigationTitle("Session")
        .onReceive(timer) { newValue in
            currentDate = newValue
        }
    }
}
