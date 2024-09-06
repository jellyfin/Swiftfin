//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import Stinsen
import SwiftUI
import VLCUI

struct TopBarTitleView: View {

    @State
    private var contentSize: CGSize = .zero

    let item: BaseItemDto

    @ViewBuilder
    private var subtitle: some View {
        if let subtitle = item.subtitle {
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white)
                .trackingSize($contentSize)
        }
    }

    var body: some View {
        Text(item.displayTitle)
            .font(.title3)
            .fontWeight(.bold)
            .lineLimit(1)
            .trackingSize($contentSize)
            .overlay(alignment: .bottomLeading) {
                subtitle
                    .offset(y: contentSize.height + 10)
            }
    }
}

extension VideoPlayer.Overlay {

    struct TopBarView: View {

        @EnvironmentObject
        private var manager: VideoPlayerManager

        var body: some View {
            HStack(alignment: .center) {
                Button("Close", systemImage: "xmark") {
                    manager.send(.stop)
                }
                .frame(width: 30, alignment: .leading)
                .contentShape(Rectangle())
                .labelStyle(.iconOnly)
                .buttonStyle(ScalingButtonStyle(scale: 0.8))

                TopBarTitleView(item: manager.item)

                Spacer()

                VideoPlayer.Overlay.BarActionButtons()
                    .buttonStyle(ScalingButtonStyle(scale: 0.8))
            }
            .font(.system(size: 24))
        }
    }
}
