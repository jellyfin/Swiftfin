//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct NavigationBar: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @Router
        private var router

        private var fontSize: CGFloat {
            UIDevice.isTV ? 34 : 24
        }

        private func onPressed(isPressed: Bool) {
            if isPressed {
                containerState.timer.stop()
            } else {
                containerState.timer.poke()
            }
        }

        @ViewBuilder
        private var closeButton: some View {
            Button {
                if containerState.isPresentingSupplement {
                    containerState.select(supplement: nil)
                } else {
                    manager.stop()
                    router.dismiss()
                }
            } label: {
                AlternateLayoutView {
                    Image(systemName: "xmark")
                } content: {
                    Label(
                        L10n.close,
                        systemImage: containerState.isPresentingSupplement ? "chevron.down" : "xmark"
                    )
                }
                .contentShape(Rectangle())
            }
        }

        var body: some View {
            HStack(alignment: UIDevice.isTV ? .bottom : .center) {

                if !UIDevice.isTV {
                    closeButton
                }

                TitleView(item: manager.item)
                    .frame(maxWidth: .infinity, alignment: .leading)

                AlternateLayoutView(alignment: .trailing) {
                    Color.clear
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .frame(height: fontSize)
                        .padding()
                } content: {
                    ActionButtons()
                }
            }
            .font(.system(size: fontSize, weight: .semibold))
            .buttonStyle(OverlayButtonStyle(onPressed: onPressed))
            #if os(iOS)
                .background {
                    EmptyHitTestView()
                }
            #endif
        }
    }
}

extension VideoPlayer.PlaybackControls.NavigationBar {

    struct TitleView: PlatformView {

        @State
        private var subtitleContentSize: CGSize = .zero

        let item: BaseItemDto

        private var _titleSubtitle: (title: String, subtitle: String?) {
            if item.type == .episode {
                if let parentTitle = item.parentTitle {
                    return (title: parentTitle, subtitle: item.seasonEpisodeLabel)
                }
            }

            return (title: item.displayTitle, subtitle: nil)
        }

        @ViewBuilder
        private func _subtitle(_ subtitle: String) -> some View {
            Text(subtitle)
                .font(UIDevice.isTV ? .callout : .subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .trackingSize($subtitleContentSize)
        }

        var iOSView: some View {
            Text(_titleSubtitle.title)
                .fontWeight(.semibold)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottomLeading) {
                    if let subtitle = _titleSubtitle.subtitle {
                        _subtitle(subtitle)
                            .lineLimit(1)
                            .offset(y: subtitleContentSize.height)
                    }
                }
        }

        var tvOSView: some View {
            VStack(alignment: .leading) {
                if let subtitle = _titleSubtitle.subtitle {
                    Text(subtitle)
                        .font(UIDevice.isTV ? .callout : .subheadline)
                        .fontWeight(.medium)
                }

                Text(_titleSubtitle.title)
                    .font(UIDevice.isTV ? .title2 : .body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
        }
    }
}
