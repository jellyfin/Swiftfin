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

// TODO: inactive session device image

extension ActiveSessionsView {

    struct ActiveSessionRow: View {

        @CurrentDate
        private var currentDate: Date

        @ObservedObject
        private var box: BindingBox<SessionInfo?>

        private let onSelect: () -> Void

        // parent list won't show row if value is nil anyways
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
                        value: Text(lastActivityDate, format: .relative(presentation: .numeric, unitsStyle: .narrow))
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
