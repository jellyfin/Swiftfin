//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ActiveSessionsView {

    struct ActiveSessionRow: View {

        @CurrentDate
        private var currentDate: Date

        @ObservedObject
        private var box: BindingBox<SessionInfo?>

        private let onSelect: () -> Void

        private var session: SessionInfo {
            box.value ?? .init()
        }

        init(box: BindingBox<SessionInfo?>, onSelect action: @escaping () -> Void) {
            self.box = box
            self.onSelect = action
        }

        @ViewBuilder
        private var rowLeading: some View {
            // TODO: better handling for different poster types
            Group {
                if let nowPlayingItem = session.nowPlayingItem {
                    if nowPlayingItem.type == .audio {
                        ZStack {
                            Color.clear

                            ImageView(nowPlayingItem.squareImageSources(maxWidth: 60))
                                .failure {
                                    SystemImageContentView(systemName: nowPlayingItem.systemImage)
                                }
                        }
                        .squarePosterStyle()
                        .frame(width: 60, height: 60)
                    } else {
                        ZStack {
                            Color.clear

                            ImageView(nowPlayingItem.portraitImageSources(maxWidth: 60))
                                .failure {
                                    SystemImageContentView(systemName: nowPlayingItem.systemImage)
                                }
                        }
                        .posterStyle(.portrait)
                        .frame(width: 60, height: 90)
                    }
                } else {
                    ZStack {
                        session.device.clientColor

                        Image(session.device.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40)
                    }
                    .squarePosterStyle()
                    .frame(width: 60, height: 60)
                }
            }
            .frame(width: 60, height: 90)
            .posterShadow()
            .padding(.vertical, 8)
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

                if let client = session.client {
                    TextPairView(leading: L10n.client, trailing: client)
                }

                if let device = session.deviceName {
                    TextPairView(leading: L10n.device, trailing: device)
                }

                if let lastActivityDate = session.lastActivityDate {
                    TextPairView(
                        L10n.lastSeen,
                        value: Text(lastActivityDate, format: .lastSeen)
                    )
                    .id(currentDate)
                    .monospacedDigit()
                }
            }
            .font(.subheadline)
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
    }
}
