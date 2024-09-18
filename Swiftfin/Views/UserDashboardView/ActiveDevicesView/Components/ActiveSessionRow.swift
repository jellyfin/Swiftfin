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
                                        .cornerRadius(4)
                                }
                                .placeholder { imageSource in
                                    ImageView.DefaultPlaceholderView(blurHash: imageSource.blurHash)
                                        .frame(width: 75)
                                        .cornerRadius(4)
                                }
                                .failure {
                                    EmptyView()
                                }
                                .id(nowPlayingItem.portraitImageSources(maxWidth: 75).hashValue)
                        }

                        sessionDetails
                    }
                    .padding(.horizontal, 16)
                    Divider()
                        .padding(.vertical, 8)
                }
            }
        }

        // MARK: - Session Details

        @ViewBuilder
        private var sessionDetails: some View {
            if let nowPlayingItem = session.nowPlayingItem {
                VStack(alignment: .leading) {
                    Text(session.userName ?? L10n.unknown)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(nowPlayingItem.name ?? L10n.unknown)
                        .foregroundColor(.primary)

                    ProgressSection(
                        item: nowPlayingItem,
                        playState: session.playState,
                        transcodingInfo: session.transcodingInfo
                    )
                    .foregroundColor(.secondary)
                    .font(.caption)
                }
            } else {
                VStack(alignment: .leading) {
                    Text(session.userName ?? L10n.unknown)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    HStack {
                        Text(L10n.deviceWithString(""))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(session.deviceName ?? L10n.unknown)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)

                    HStack {
                        Text(L10n.versionWithString(""))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(session.applicationVersion ?? L10n.unknown)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)

                    Spacer()

                    if let lastActivityDate = session.lastActivityDate {
                        ConnectionSection(
                            lastActivityDate: lastActivityDate,
                            currentDate: Date(),
                            prefixText: true
                        )
                        .foregroundColor(.secondary)
                        .font(.caption)
                    } else {
                        Text(session.deviceName ?? session.client ?? L10n.unknown)
                            .font(.headline)
                        Spacer()
                    }
                }
            }
        }
    }
}
