//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ActiveDevicesView {

    struct ActiveSessionRow: View {

        let session: SessionInfo
        let onSelect: () -> Void

        @ViewBuilder
        private var rowLeading: some View {
            // TODO: better handling for different poster types
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
            .frame(width: 60)
            .posterShadow()
            .padding(.vertical, 8)
        }

        var body: some View {
            ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
                rowLeading
            } content: {
                if let nowPlayingItem = session.nowPlayingItem, let playState = session.playState {
                    activeSessionDetails(nowPlayingItem, playState: playState)
                } else {
                    idleSessionDetails
                }
            }
            .onSelect(perform: onSelect)
        }

        @ViewBuilder
        private func activeSessionDetails(_ nowPlayingItem: BaseItemDto, playState: PlayerStateInfo) -> some View {
            VStack(alignment: .leading) {
                Text(session.userName ?? L10n.unknown)
                    .font(.headline)

                Text(nowPlayingItem.name ?? L10n.unknown)

                ProgressSection(
                    item: nowPlayingItem,
                    playState: playState,
                    transcodingInfo: session.transcodingInfo
                )
            }
            .font(.subheadline)
        }

        @ViewBuilder
        private var idleSessionDetails: some View {
            VStack(alignment: .leading) {

                Text(session.userName ?? L10n.unknown)
                    .font(.headline)

//                ActiveDevicesView.ClientSection(
//                    client: session.client,
//                    deviceName: session.deviceName,
//                    applicationVersion: session.applicationVersion
//                )
//                .font(.subheadline)

                if let lastActivityDate = session.lastActivityDate {
                    ConnectionSection(
                        lastActivityDate: lastActivityDate,
                        currentDate: Date(),
                        prefixText: true
                    )
                    .font(.subheadline)
                }
            }
        }
    }
}

#Preview {
    VStack {
        ActiveDevicesView.ActiveSessionRow(
            session: .init(
                additionalUsers: nil,
                applicationVersion: nil,
                capabilities: nil,
                client: nil,
                deviceID: nil,
                deviceName: nil,
                deviceType: nil,
                fullNowPlayingItem: nil,
                hasCustomDeviceName: nil,
                id: nil,
                isActive: nil,
                lastActivityDate: nil,
                lastPlaybackCheckIn: nil,
                nowPlayingItem: .init(name: "New Girl", runTimeTicks: 30000),
                nowPlayingQueue: nil,
                nowPlayingQueueFullItems: nil,
                nowViewingItem: nil,
                playState: .init(playMethod: .directPlay, positionTicks: 10000),
                playableMediaTypes: nil,
                playlistItemID: nil,
                remoteEndPoint: nil,
                serverID: nil,
                supportedCommands: nil,
                isSupportsMediaControl: nil,
                isSupportsRemoteControl: nil,
                transcodingInfo: nil,
                userID: nil,
                userName: "Steve Jobs",
                userPrimaryImageTag: nil
            ),
            onSelect: {}
        )
    }
}
