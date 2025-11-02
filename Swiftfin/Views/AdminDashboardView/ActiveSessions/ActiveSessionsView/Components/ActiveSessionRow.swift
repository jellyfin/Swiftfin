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
        private var box: BindingBox<SessionInfoDto?>

        private let onSelect: () -> Void

        private var session: SessionInfoDto {
            box.value ?? .init()
        }

        init(box: BindingBox<SessionInfoDto?>, onSelect action: @escaping () -> Void) {
            self.box = box
            self.onSelect = action
        }

        @ViewBuilder
        private var rowLeading: some View {
            Group {
                if let nowPlayingItem = session.nowPlayingItem {
                    PosterImage(
                        item: nowPlayingItem,
                        type: nowPlayingItem.preferredPosterDisplayType,
                        contentMode: .fit
                    )
                    .frame(width: 60)
                } else {
                    ZStack {
                        session.device.clientColor

                        Image(session.device.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40)
                    }
                    .posterStyle(.square)
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
                    .multilineTextAlignment(.leading)
                    .font(.headline)

                Text(nowPlayingItem.name ?? L10n.unknown)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                ProgressSection(
                    item: nowPlayingItem,
                    playState: playState,
                    transcodingInfo: session.transcodingInfo,
                    showTranscodeReason: true
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
                    LabeledContent(
                        L10n.client,
                        value: client
                    )
                }

                if let device = session.deviceName {
                    LabeledContent(
                        L10n.device,
                        value: device
                    )
                }

                if let lastActivityDate = session.lastActivityDate {
                    LabeledContent(
                        L10n.lastSeen,
                        value: lastActivityDate,
                        format: .lastSeen
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
