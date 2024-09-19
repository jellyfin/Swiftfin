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
        var session: SessionInfo
        var onSelect: () -> Void

        // MARK: - Body

        var body: some View {
            Button(action: onSelect) {
                VStack {
                    HStack(alignment: .center, spacing: 12) {
                        if let nowPlayingItem = session.nowPlayingItem {
                            ImageView(nowPlayingItem.portraitImageSources(maxWidth: 75))
                                .image { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 75)
                                        .cornerRadius(8)
                                }
                                .placeholder { imageSource in
                                    ImageView.DefaultPlaceholderView(blurHash: imageSource.blurHash)
                                        .frame(width: 75)
                                        .cornerRadius(8)
                                }
                                .failure {
                                    EmptyView()
                                }
                                .id(nowPlayingItem.portraitImageSources(maxWidth: 75).hashValue)
                        } else {
                            Image(.jellyfinBlobBlue)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.primary)
                                .padding(8)
                                .frame(width: 75)
                        }

                        sessionDetails
                    }
                    .padding(16)
                    Divider()
                }
            }
        }

        // MARK: - Session Details

        @ViewBuilder
        private var sessionDetails: some View {
            if let nowPlayingItem = session.nowPlayingItem {
                activeSessionDetails(nowPlayingItem)
            } else {
                idleSessionDetails
            }
        }

        @ViewBuilder
        private func activeSessionDetails(_ nowPlayingItem: BaseItemDto) -> some View {
            VStack(alignment: .leading) {
                Text(session.userName ?? L10n.unknown)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(nowPlayingItem.name ?? L10n.unknown)
                    .foregroundColor(.primary)

                Spacer()

                ProgressSection(
                    item: nowPlayingItem,
                    playState: session.playState,
                    transcodingInfo: session.transcodingInfo
                )
                .foregroundColor(.secondary)
                .font(.caption)
            }
        }

        @ViewBuilder
        private var idleSessionDetails: some View {
            VStack(alignment: .leading) {
                Text(session.userName ?? L10n.unknown)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                ActiveDevicesView.ClientSection(
                    client: session.client,
                    deviceName: session.deviceName,
                    applicationVersion: session.applicationVersion
                )
                .font(.subheadline)
                .foregroundColor(.primary)

                Spacer()

                if let lastActivityDate = session.lastActivityDate {
                    ConnectionSection(
                        lastActivityDate: lastActivityDate,
                        currentDate: Date(),
                        prefixText: true
                    )
                    .font(.subheadline)
                    .foregroundColor(.primary)
                }
            }
        }
    }
}
