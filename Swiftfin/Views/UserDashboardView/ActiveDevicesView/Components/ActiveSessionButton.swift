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
    struct ActiveSessionButton: View {
        var session: SessionInfo
        var onSelect: () -> Void

        // MARK: Session Details

        @ViewBuilder
        private var sessionDetails: some View {
            VStack(alignment: .leading) {
                if let nowPlayingItem = session.nowPlayingItem {
                    UserDashboardView.ContentSection(item: nowPlayingItem)
                } else {
                    UserDashboardView.ClientSection(
                        client: session.client,
                        deviceName: session.deviceName,
                        applicationVersion: session.applicationVersion
                    )
                }
            }
        }

        // MARK: Header and Footer

        private var headerSection: some View {
            UserDashboardView.UserSection(
                userName: session.userName,
                client: session.client
            )
        }

        @ViewBuilder
        private var footerSection: some View {
            if let nowPlayingItem = session.nowPlayingItem {
                UserDashboardView.ProgressSection(
                    item: nowPlayingItem,
                    playState: session.playState,
                    transcodingInfo: session.transcodingInfo
                )
                .font(.caption)
            } else if let lastActivityDate = session.lastActivityDate {
                UserDashboardView.ConnectionSection(
                    lastActivityDate: lastActivityDate,
                    currentDate: Date(),
                    prefixText: true
                )
            }
        }

        // MARK: Body

        var body: some View {
            Button(action: onSelect) {
                VStack(alignment: .leading) {
                    headerSection
                        .foregroundColor(.primary)

                    Spacer()

                    HStack(alignment: .top, spacing: 16) {
                        if let nowPlayingItem = session.nowPlayingItem {
                            ImageView(nowPlayingItem.portraitImageSources(maxWidth: 150))
                                .image { image in
                                    image
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(4)
                                }
                                .placeholder { imageSource in
                                    ImageView.DefaultPlaceholderView(blurHash: imageSource.blurHash)
                                        .cornerRadius(4)
                                }
                                .failure {
                                    EmptyView()
                                }
                                .id(nowPlayingItem.portraitImageSources(maxWidth: 150).hashValue)
                        }
                        sessionDetails
                            .foregroundColor(.primary)
                    }

                    Spacer()
                    footerSection
                        .foregroundColor(.primary)
                }
                .padding(16)
                .background(Color.accentColor.opacity(0.3))
                .posterStyle(.landscape)
                .posterShadow()
            }
        }
    }
}
