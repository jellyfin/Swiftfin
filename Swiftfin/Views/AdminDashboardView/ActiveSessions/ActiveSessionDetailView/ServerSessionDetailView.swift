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
    var box: BindingBox<SessionInfoDto?>

    // MARK: Create Idle Content View

    @ViewBuilder
    private func idleContent(session: SessionInfoDto) -> some View {
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
        session: SessionInfoDto,
        nowPlayingItem: BaseItemDto,
        playState: PlayerStateInfo
    ) -> some View {
        List {

            AdminDashboardView.MediaItemSection(item: nowPlayingItem)

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
