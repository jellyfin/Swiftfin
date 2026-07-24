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

struct GuideChannelColumn: View {

    private let layout = LiveTVGuideLayout()

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    var guideViewModel: GuideViewModel

    let channels: IdentifiedArrayOf<BaseItemDto>
    let bottomInset: CGFloat
    let onSelectChannel: (BaseItemDto) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if guideViewModel.now >= guideViewModel.startDate {
                    OnNowButton {
                        guideViewModel.proxy.scrollTo(
                            centering: layout.width(from: guideViewModel.startDate, to: guideViewModel.now)
                        )
                    }
                }
            }
            .frame(width: layout.channelColumnWidth, height: layout.rulerHeight)

            Divider()

            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(channels, id: \.id) { channel in
                        GuideChannelButton(
                            channel: channel,
                            action: { onSelectChannel(channel) }
                        )
                        .isSelected(channel.id != nil && channel.id == guideViewModel.selectedChannelID)
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

                guideViewModel.proxy.registerVertical(scrollView)
            }
        }
        .frame(width: layout.channelColumnWidth)
        #if os(tvOS)
            .focusSection()
        #endif
    }
}

extension GuideChannelColumn {

    private struct OnNowButton: View {

        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Content()
            }
            .buttonStyle(GuideButtonStyle())
            #if os(tvOS)
                .focusEffectDisabled()
            #endif
        }
    }

    private struct Content: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isFocused)
        private var isFocused

        var body: some View {
            Text(L10n.onNow)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .backport
                .glassEffect(
                    .regular.selection(
                        tint: isFocused ? accentColor : nil,
                        foregroundColor: isFocused ? accentColor.overlayColor : .primary
                    )
                    .interactive(false),
                    in: .capsule
                )
        }
    }
}
