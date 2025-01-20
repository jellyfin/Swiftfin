//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI
import SwiftUIIntrospect

struct ActiveSessionDetailView: View {

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @ObservedObject
    var box: BindingBox<SessionInfo?>

    // MARK: Create Idle Content View

    @ViewBuilder
    private func idleContent(session: SessionInfo) -> some View {
        List {
            if let userID = session.userID {
                let user = UserDto(id: userID, name: session.userName)

                AdminDashboardView.UserSection(
                    user: user,
                    lastActivityDate: session.lastActivityDate
                ) {
                    router.route(to: \.userDetails, user)
                }
            }

            AdminDashboardView.DeviceSection(
                client: session.client,
                device: session.deviceName,
                version: session.applicationVersion
            )
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
                ActiveSessionsView.ProgressSection(
                    item: nowPlayingItem,
                    playState: playState,
                    transcodingInfo: session.transcodingInfo
                )
            }

            if let userID = session.userID {
                let user = UserDto(id: userID, name: session.userName)

                AdminDashboardView.UserSection(
                    user: user,
                    lastActivityDate: session.lastPlaybackCheckIn
                ) {
                    router.route(to: \.userDetails, user)
                }
            }

            AdminDashboardView.DeviceSection(
                client: session.client,
                device: session.deviceName,
                version: session.applicationVersion
            )

            // TODO: allow showing item stream details?
            // TODO: don't show codec changes on direct play?
            Section(L10n.streams) {
                if let playMethodDisplayTitle = session.playMethodDisplayTitle {
                    TextPairView(leading: L10n.method, trailing: playMethodDisplayTitle)
                }

                StreamSection(
                    nowPlayingItem: nowPlayingItem,
                    transcodingInfo: session.transcodingInfo
                )
            }

            if let transcodeReasons = session.transcodingInfo?.transcodeReasons, transcodeReasons.isNotEmpty {
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

                VStack(alignment: .leading) {

                    if let parent = item.parentTitle {
                        Text(parent)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Text(item.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom)
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
                Text(L10n.noSession)
            }
        }
        .animation(.linear(duration: 0.2), value: box.value)
        .navigationTitle(L10n.session)
    }
}
