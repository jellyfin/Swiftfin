//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import JellyfinAPI
import SwiftUI

struct GuideChannelColumnCell: View {

    @Default(.accentColor)
    private var accentColor

    @Namespace
    private var namespace

    @Router
    private var router

    let channel: BaseItemDto
    let width: CGFloat
    let height: CGFloat

    private func play() {
        guard let userSession = Container.shared.currentUserSession() else { return }

        router.route(
            to: .videoPlayer(
                provider: channel.getPlaybackItemProvider(userSession: userSession)
            ),
            in: namespace
        )
    }

    var body: some View {
        Button(action: play) {
            Content(
                channel: channel,
                width: width,
                height: height,
                accentColor: accentColor
            )
        }
        .buttonStyle(GuideButtonStyle())
    }
}

extension GuideChannelColumnCell {

    private struct Content: View {

        @Environment(\.isFocused)
        private var isFocused

        let channel: BaseItemDto
        let width: CGFloat
        let height: CGFloat
        let accentColor: Color

        var body: some View {
            PosterImage(item: channel, type: .square, contentMode: .fill, maxWidth: 240)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    if isFocused {
                        ZStack {
                            Color.black.opacity(0.5)

                            Image(systemName: "play.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(accentColor, lineWidth: isFocused ? 4 : 0)
                }
                .padding(4)
                .frame(width: width, height: height)
        }
    }
}
