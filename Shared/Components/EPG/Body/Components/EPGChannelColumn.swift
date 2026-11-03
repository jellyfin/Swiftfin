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
@_spi(Advanced) import SwiftUIIntrospect

struct EPGChannelColumn: View {

    @AdaptiveLayout
    private var viewLayout

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    var viewModel: EPGViewModel

    let proxy: EPGScrollProxy
    let selectedChannelID: String?
    let bottomInset: CGFloat
    let action: (BaseItemDto) -> Void

    var body: some View {
        let layout = EPGLayout(viewLayout: viewLayout)

        VStack(spacing: 0) {
            ZStack {
                if !viewLayout.isLarge, viewModel.now >= viewModel.startDate {
                    Button {
                        proxy.scrollTo(
                            centering: layout.width(from: viewModel.startDate, to: viewModel.now)
                        )
                    } label: {
                        Text(L10n.onNow)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .backport
                            .glassEffect(
                                .regular.interactive(false),
                                in: .capsule
                            )
                    }
                    .buttonStyle(EPGButtonStyle())
                }
            }
            .frame(width: layout.channelColumnWidth, height: layout.rulerHeight)

            Divider()

            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.channels) { channel in
                        EPGChannelButton(
                            channel: channel.snapshot,
                            action: { action(channel.snapshot) }
                        )
                        .isSelected(channel.itemID == selectedChannelID)
                    }
                }
                .tint(accentColor)
                .padding(.bottom, bottomInset)
            }
            .scrollIndicators(.hidden)
            .introspect(.scrollView, on: .iOS(.v18...), .tvOS(.v18...)) { scrollView in
                scrollView.contentInsetAdjustmentBehavior = viewLayout.isLarge ? .never : .automatic

                proxy.registerVertical(scrollView)
            }
        }
        .frame(width: layout.channelColumnWidth)
        .focusSection()
    }
}
