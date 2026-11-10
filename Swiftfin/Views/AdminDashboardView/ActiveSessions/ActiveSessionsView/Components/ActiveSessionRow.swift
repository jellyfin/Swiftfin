//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ActiveSessionsView {

    struct ActiveSessionRow: View {

        @AdaptiveLayout
        private var viewLayout

        @CurrentDate
        private var currentDate: Date

        @ObservedObject
        var viewModel: SessionViewModel

        let posterDisplayType: PosterDisplayType
        let action: () -> Void

        private var session: SessionInfoDto {
            viewModel.session
        }

        private var isPlaying: Bool {
            session.nowPlayingItem != nil && session.playState != nil
        }

        private var rowLeading: some View {
            let size: CGSize = switch posterDisplayType {
            case .landscape:
                CGSize(width: 90, height: 60)
            case .portrait:
                CGSize(width: 60, height: 90)
            case .square:
                CGSize(width: 60, height: 60)
            }

            return PosterImage(
                item: session,
                type: posterDisplayType,
                size: .extraSmall
            )
            .id(session.nowPlayingItem?.id)
            .overlay {
                if session.nowPlayingItem == nil {
                    ZStack {
                        session.device.clientColor

                        Image(session.device.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(8)
                    }
                    .posterStyle(posterDisplayType)
                }
            }
            .frame(width: size.width, height: size.height)
            .subtleShadow()
        }

        private func activeSessionDetails(_ nowPlayingItem: BaseItemDto, playState: PlayerStateInfo) -> some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.userName ?? L10n.unknown)
                    .multilineTextAlignment(.leading)
                    .font(.headline)

                Text(nowPlayingItem.name ?? L10n.unknown)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)

                ProgressSection(
                    item: nowPlayingItem,
                    playState: playState,
                    transcodingInfo: session.transcodingInfo,
                    showTranscodeReason: true
                )
            }
            .font(.subheadline)
        }

        private var idleSessionDetails: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.userName ?? L10n.unknown)
                    .font(.headline)

                DotHStack {
                    if let client = session.client {
                        Text(client)
                    }

                    if let device = session.deviceName {
                        Text(device)
                    }
                }
                .lineLimit(1)

                LabeledContent(L10n.lastSeen) {
                    Text(session.lastActivityDate, format: .lastSeen)
                        .id(currentDate)
                        .monospacedDigit()
                }
            }
            .font(.subheadline)
        }

        var body: some View {
            ListRow(insets: .init(vertical: 8, horizontal: viewLayout.edgePadding)) {
                rowLeading
            } content: {
                if let nowPlayingItem = session.nowPlayingItem, let playState = session.playState {
                    activeSessionDetails(nowPlayingItem, playState: playState)
                } else {
                    idleSessionDetails
                }
            } action: {
                action()
            }
            .withViewContext(.isListRowSeparatorVisible)
        }
    }
}
