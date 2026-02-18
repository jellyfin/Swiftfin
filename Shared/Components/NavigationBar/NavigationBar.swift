//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: determine smaller font size for title

extension VideoPlayer.PlaybackControls {

    struct NavigationBar: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @Router
        private var router

        #if os(tvOS)
        var focusedActionButton: FocusState<VideoPlayerActionButton?>.Binding?

        init(focusedActionButton: FocusState<VideoPlayerActionButton?>.Binding? = nil) {
            self.focusedActionButton = focusedActionButton
        }
        #endif

        private var fontSize: CGFloat = !UIDevice.isTV ? 24 : 36
        private var fontWeight: Font.Weight = !UIDevice.isTV ? .semibold : .regular

        private func onPressed(isPressed: Bool) {
            if isPressed {
                containerState.timer.stop()
            } else {
                containerState.timer.poke()
            }
        }

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

                AlternateLayoutView {
                    ActionButtons()
                } content: {
                    #if os(tvOS)
                    ActionButtons(focusedActionButton: focusedActionButton)
                        .focusSection()
                    #else
                    ActionButtons()
                    #endif
                }
            }
            .font(.system(size: fontSize, weight: fontWeight))
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

    struct TitleView: View {

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

        private func _subtitle(_ subtitle: String) -> some View {
            Text(subtitle)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .trackingSize($subtitleContentSize)
        }

        var body: some View {
            let titleSubtitle = self._titleSubtitle

            #if os(iOS)
            Text(titleSubtitle.title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .frame(minWidth: max(50, subtitleContentSize.width))
                .overlay(alignment: .bottomLeading) {
                    if let subtitle = titleSubtitle.subtitle {
                        _subtitle(subtitle)
                            .lineLimit(1)
                            .offset(y: subtitleContentSize.height)
                    }
                }
            #else
            VStack(alignment: .leading) {
                Text(titleSubtitle.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if let subtitle = titleSubtitle.subtitle {
                    _subtitle(subtitle)
                        .lineLimit(1)
                }
            }
            .frame(minWidth: max(50, subtitleContentSize.width))
            #endif
        }
    }
}
