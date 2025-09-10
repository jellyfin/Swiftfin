//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct NavigationBar: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        private func onPressed(isPressed: Bool) {
            if isPressed {
                containerState.timer.stop()
            } else {
                containerState.timer.poke()
            }
        }

        var body: some View {
            HStack(alignment: .center) {
                Button(L10n.close, systemImage: "xmark") {
                    manager.send(.stop)
                }

                TitleView(item: manager.item)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ActionButtons()
            }
            .background {
                EmptyHitTestView()
            }
            .font(.system(size: 24, weight: .semibold))
            .buttonStyle(OverlayButtonStyle(onPressed: onPressed))
        }
    }
}

extension VideoPlayer.PlaybackControls.NavigationBar {

    struct TitleView: View {

        @State
        private var subtitleContentSize: CGSize = .zero

        let item: BaseItemDto

        @ViewBuilder
        private var subtitle: some View {
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .trackingSize($subtitleContentSize)
            }
        }

        var body: some View {
            Text(item.displayTitle)
                .fontWeight(.bold)
                .lineLimit(1)
                .overlay(alignment: .bottomLeading) {
                    subtitle
                        .lineLimit(1)
                        .offset(y: subtitleContentSize.height)
                }
        }
    }
}
