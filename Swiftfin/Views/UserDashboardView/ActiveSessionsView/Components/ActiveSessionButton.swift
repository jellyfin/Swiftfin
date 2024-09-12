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

extension ActiveSessionsView {
    struct ActiveSessionButton: View {
        private var session: SessionInfo
        private var onSelect: () -> Void

        @State
        private var imageSources: [ImageSource] = []

        // MARK: - Init

        init(session: SessionInfo) {
            self.session = session
            self.onSelect = {}
        }

        // MARK: Set Image Sources

        private func setImageSources() {
            Task { @MainActor in
                if let nowPlayingItem = session.nowPlayingItem {
                    switch nowPlayingItem.type {
                    case .episode:
                        self.imageSources = [nowPlayingItem.imageSource(.primary, maxWidth: 500)]
                    default:
                        self.imageSources = [nowPlayingItem.imageSource(.backdrop, maxWidth: 500)]
                    }
                } else {
                    self.imageSources = []
                }
            }
        }

        // MARK: Session Details

        @ViewBuilder
        private var sessionDetails: some View {
            VStack(alignment: .leading) {
                // Create the Header with the User & Client
                ActiveSessionsView.UserSection(
                    userName: session.userName,
                    client: session.client
                )

                Spacer()

                // Show the Stream Details if something is being streamed. Otherwise, show the Last Seen date.
                if let nowPlayingItem = session.nowPlayingItem {
                    ActiveSessionsView.ContentSection(item: session.nowPlayingItem)

                    Spacer()

                    ActiveSessionsView.ProgressSection(
                        item: nowPlayingItem,
                        playState: session.playState,
                        transcodingInfo: session.transcodingInfo
                    )
                    .font(.caption)

                } else {
                    ActiveSessionsView.ClientSection(
                        client: session.client,
                        deviceName: session.deviceName,
                        applicationVersion: session.applicationVersion
                    )

                    Spacer()

                    if let lastActivityDate = session.lastActivityDate {
                        ActiveSessionsView.ConnectionSection(
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
            Button {
                onSelect()
            } label: {
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
            .onAppear(perform: setImageSources)
            .onChange(of: session.nowPlayingItem) { _ in
                setImageSources()
            }
        }
    }
}

extension ActiveSessionsView.ActiveSessionButton {
    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }

    private func copy<Value>(modifying keyPath: WritableKeyPath<ActiveSessionsView.ActiveSessionButton, Value>, with value: Value) -> Self {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
}
