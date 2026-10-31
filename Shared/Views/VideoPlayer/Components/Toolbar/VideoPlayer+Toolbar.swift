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

    struct Toolbar: View {

        typealias ViewState = VideoPlayer.ViewState

        @AdaptiveLayout
        private var viewLayout

        @Environment(ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        @Router
        private var router

        private var closeButton: some View {
            Button {
                if viewState.isPresentingSupplement {
                    viewState.selectedSupplementID = nil
                } else {
                    mediaSession.stop()
                    router.dismiss()
                }
            } label: {
                Label(
                    L10n.close,
                    systemImage: viewState.isPresentingSupplement ? "chevron.down" : "xmark"
                )
                .labelStyle(.iconOnly)
            }
            .frame(width: viewLayout.toolbarButtonSize, height: viewLayout.toolbarButtonSize)
        }

        private var content: some View {
            HStack(alignment: viewLayout.value(standard: .center, large: .bottom)) {

                if !viewLayout.isLarge {
                    closeButton
                        .modifier(OverlayBarButtonStyleModifier())
                }

                TitleView(item: mediaSession.item)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ActionButtons()
                    .frame(height: viewLayout.toolbarButtonSize)
                    .padding(.horizontal)
            }
        }

        var body: some View {
            content
                .font(.system(size: viewLayout.isLarge ? 30 : 24, weight: .semibold))
                .menuStyle(OverlayMenuStyle())
                #if os(iOS)
                .background {
                    EmptyHitTestView()
                }
                #endif
        }
    }
}

extension VideoPlayer.PlaybackControls.Toolbar {

    struct TitleView: PresentationView {

        @AdaptiveLayout
        private var viewLayout

        @State
        private var subtitleContentSize: CGSize = .zero

        @SharedBaseItem
        var item: BaseItemDto

        private var _titleSubtitle: (title: String, subtitle: String?) {
            if item.type == .episode, let parentTitle = item.parentTitle {
                return (title: parentTitle, subtitle: item.seasonEpisodeLabel)
            }

            return (title: item.displayTitle, subtitle: nil)
        }

        private func _subtitle(_ subtitle: String) -> some View {
            Text(subtitle)
                .font(viewLayout.value(standard: .subheadline, large: .caption))
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .trackingSize($subtitleContentSize)
        }

        var standardView: some View {
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

        var largeView: some View {
            VStack(alignment: .leading) {
                if let subtitle = _titleSubtitle.subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .fontWeight(.medium)
                }

                Text(_titleSubtitle.title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .lineLimit(1)
        }
    }
}
