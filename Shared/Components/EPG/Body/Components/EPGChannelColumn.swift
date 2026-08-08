//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import IdentifiedCollections
import JellyfinAPI
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct EPGChannelColumn: View {

    private let layout = EPGLayout()

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    var viewModel: EPGViewModel

    let channels: IdentifiedArrayOf<BaseItemDto>
    let selectedChannelID: String?
    let bottomInset: CGFloat
    let onSelect: (BaseItemDto) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                #if os(iOS)
                // On Now Button
                if viewModel.now >= viewModel.startDate {
                    Button {
                        viewModel.proxy.scrollTo(
                            centering: layout.width(from: viewModel.startDate, to: viewModel.now)
                        )
                    } label: {
                        Text(L10n.onNow)
                            .font(.caption2.weight(.semibold))
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
                #endif
            }
            .frame(width: layout.channelColumnWidth, height: layout.rulerHeight)

            Divider()

            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(channels, id: \.id) { channel in
                        EPGChannelButton(
                            channel: channel,
                            action: { onSelect(channel) }
                        )
                        .isSelected(channel.id != nil && channel.id == selectedChannelID)
                    }
                }
                .tint(accentColor)
                .padding(.bottom, bottomInset)
            }
            .scrollIndicators(.hidden)
            .introspect(.scrollView, on: .iOS(.v15...), .tvOS(.v15...)) { scrollView in
                #if os(tvOS)
                scrollView.contentInsetAdjustmentBehavior = .never
                #endif

                viewModel.proxy.registerVertical(scrollView)
            }
        }
        .frame(width: layout.channelColumnWidth)
        .focusSection()
    }
}
