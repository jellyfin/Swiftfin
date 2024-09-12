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

extension UserDashboardView {
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
                    self.imageSources = [nowPlayingItem.imageSource(.primary)]
                default:
                    self.imageSources = [nowPlayingItem.imageSource(.backdrop)]
                }
            }
        }

        // MARK: Session Details

        @ViewBuilder
        private var sessionDetails: some View {
            VStack(alignment: .leading) {
                UserDashboardView.UserSection(
                    userName: session.userName,
                    client: session.client
                )

                Spacer()

                if let nowPlayingItem = session.nowPlayingItem {
                    UserDashboardView.ContentSection(item: nowPlayingItem)

                    Spacer()

                    UserDashboardView.ProgressSection(
                        item: nowPlayingItem,
                        playState: session.playState,
                        transcodingInfo: session.transcodingInfo
                    )
                    .font(.caption)

                } else {
                    UserDashboardView.ClientSection(
                        client: session.client,
                        deviceName: session.deviceName,
                        applicationVersion: session.applicationVersion
                    )

                    Spacer()

                    if let lastActivityDate = session.lastActivityDate {
                        UserDashboardView.ConnectionSection(
                            lastActivityDate: lastActivityDate,
                            currentDate: Date(),
                            prefixText: true
                        )
                    }
                }
            }
            .padding(16)
        }

        // MARK: Create Title Label Overlay

        private func titleLabelOverlay<Content: View>(with content: Content) -> some View {
            ZStack {
                content
                Color.black.opacity(0.5)
                sessionDetails
                    .foregroundStyle(.white)
            }
        }

        // MARK: Body

        var body: some View {
            Button(action: onSelect) {
                ZStack {
                    Color.clear

                    ImageView(imageSources)
                        .image { image in
                            titleLabelOverlay(with: image)
                        }
                        .placeholder { imageSource in
                            titleLabelOverlay(with: ImageView.DefaultPlaceholderView(blurHash: imageSource.blurHash))
                        }
                        .failure {
                            Color.secondarySystemFill
                                .opacity(0.75)
                                .overlay {
                                    sessionDetails
                                        .foregroundColor(.primary)
                                }
                        }
                        .id(imageSources.hashValue)
                }
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
