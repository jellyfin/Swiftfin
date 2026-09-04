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

        static let buttonSize: CGFloat = UIDevice.isTV ? 56 : 44
        static let supplementButtonSpacing: CGFloat = UIDevice.isTV ? 20 : 10

        static var buttonSpacing: CGFloat {
            if UIDevice.supportsLiquidGlass {
                supplementButtonSpacing
            } else {
                UIDevice.isTV ? 16 : 0
            }
        }

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @Router
        private var router

        private var fontSize: CGFloat {
            UIDevice.isTV ? 30 : 24
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
                    Label(L10n.close, systemImage: "xmark")
                } content: {
                    Label(
                        L10n.close,
                        systemImage: containerState.isPresentingSupplement ? "chevron.down" : "xmark"
                    )
                }
                .contentShape(Rectangle())
            }
        }

        @ViewBuilder
        private var content: some View {
            HStack(alignment: UIDevice.isTV ? .bottom : .center) {

                if !UIDevice.isTV {
                    closeButton
                        .frame(width: Self.buttonSize, height: Self.buttonSize)
                        .modifier(OverlayBarButtonStyleModifier())
                }

                TitleView(item: manager.item)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ActionButtons()
                    .frame(height: Self.buttonSize)
                    .padding(.horizontal)
            }
        }

        var body: some View {
            Group {
                #if os(iOS)
                if #available(iOS 26.0, *), UIDevice.supportsLiquidGlass {
                    GlassEffectContainer {
                        content
                    }
                } else {
                    content
                }
                #else
                content
                #endif
            }
            .font(.system(size: fontSize, weight: .semibold))
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
                .font(UIDevice.isTV ? .caption : .subheadline)
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
