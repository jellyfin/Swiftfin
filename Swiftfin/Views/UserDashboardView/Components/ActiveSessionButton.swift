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

extension UserDashboardView /* ActiveDeviceView */ {
    struct ActiveSessionButton: View {
        var session: SessionInfo
        var onSelect: () -> Void

        @State
        private var imageSources: [ImageSource] = []

        // MARK: Set Image Sources

        private func setImageSources(for nowPlayingItem: BaseItemDto?) {
            Task { @MainActor in
                guard let nowPlayingItem = nowPlayingItem else {
                    self.imageSources = []
                    return
                }

                switch nowPlayingItem.type {
                case .episode:
                    self.imageSources = [nowPlayingItem.imageSource(.primary, maxHeight: 50)]
                default:
                    self.imageSources = [nowPlayingItem.imageSource(.backdrop, maxHeight: 50)]
                }
            }
        }

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
                        ImageView(imageSources)
                            .image { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100)
                            }
                            .placeholder { imageSource in
                                ImageView.DefaultPlaceholderView(blurHash: imageSource.blurHash)
                                    .frame(width: 100)
                            }
                            .failure {
                                EmptyView()
                            }
                            .id(imageSources.hashValue)

                        sessionDetails
                            .foregroundColor(.primary)
                    }

                    Spacer()
                    footerSection
                        .foregroundColor(.primary)
                }
                .padding(16)
                .posterStyle(.landscape)
                .posterShadow()
            }
            .onAppear {
                setImageSources(for: session.nowPlayingItem)
            }
            .onChange(of: session.nowPlayingItem) { newValue in
                setImageSources(for: newValue)
            }
        }
    }
}
