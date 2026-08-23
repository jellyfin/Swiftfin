//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct OverlayButtonStyleModifier: ViewModifier {

        @ViewBuilder
        func body(content: Content) -> some View {
            if #available(iOS 26.0, *), UIDevice.supportsLiquidGlass {
                content
                    .buttonStyle(OverlayGlassButtonStyle())
                    .buttonBorderShape(.circle)
            } else {
                content
                    .buttonStyle(OverlayButtonStyle())
            }
        }
    }

    struct OverlayMenuStyle: MenuStyle {

        @ViewBuilder
        func makeBody(configuration: Configuration) -> some View {
            if #available(iOS 26.0, tvOS 26.0, *), UIDevice.supportsLiquidGlass {
                Menu(configuration)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .labelStyle(OverlayLabelStyle())
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.primary, .secondary)
            } else {
                Menu(configuration)
                    .labelStyle(OverlayLabelStyle())
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.primary, .secondary)
            }
        }
    }

    @available(iOS 26.0, tvOS 26.0, *)
    struct OverlayGlassButtonStyle: PrimitiveButtonStyle {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        func makeBody(configuration: Configuration) -> some View {
            let button = Button(role: configuration.role) {
                if UIDevice.isTV {
                    containerState.timer.poke()
                }
                configuration.trigger()
            } label: {
                configuration.label
            }
            .buttonStyle(.glass)

            #if os(iOS)
            return button
                .onLongPressGesture(minimumDuration: .infinity) {} onPressingChanged: { isPressed in
                    if isPressed {
                        containerState.timer.stop()
                    } else {
                        containerState.timer.poke()
                    }
                }
            #else
            return button
            #endif
        }
    }

    struct OverlayButtonStyle: ButtonStyle {

        @Environment(\.isEnabled)
        private var isEnabled
        @Environment(\.isFocused)
        private var isFocused

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundStyle(isEnabled ? isFocused ? AnyShapeStyle(Color.black) : AnyShapeStyle(HierarchicalShapeStyle.primary) :
                    AnyShapeStyle(Color.gray)
                )
                .labelStyle(.iconOnly)
                .contentShape(Rectangle())
                .scaleEffect(configuration.isPressed ? 0.8 : 1)
                .animation(.bouncy(duration: 0.25, extraBounce: 0.25), value: configuration.isPressed)
                .padding(4)
                .animation(nil, value: configuration.isPressed)
                .background {
                    Circle()
                        .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.25 : isFocused ? 1 : 0))
                        .scaleEffect(configuration.isPressed ? 1 : 0.9)
                }
                .animation(.linear(duration: 0.1).delay(configuration.isPressed ? 0.2 : 0), value: configuration.isPressed)
                .padding(4)
                .onChange(of: configuration.isPressed) {
                    if configuration.isPressed {
                        containerState.timer.stop()
                    } else {
                        containerState.timer.poke()
                    }
                }
        }
    }

    struct OverlayLabelStyle: LabelStyle {

        private var size: CGFloat {
            if #available(iOS 26.0, *) {
                UIDevice.isTV ? 36 : 32
            } else {
                44
            }
        }

        func makeBody(configuration: Configuration) -> some View {
            configuration.icon
                .font(.system(size: UIDevice.isTV ? 36 : 20, weight: .semibold))
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
    }
}

struct OverlayMenuTimerModifier: ViewModifier {

    @EnvironmentObject
    private var containerState: VideoPlayerContainerState

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !UIDevice.isTV {
                    containerState.presentedMenuCount += 1
                }
            }
            .onDisappear {
                if !UIDevice.isTV {
                    containerState.presentedMenuCount -= 1
                }
            }
    }
}
