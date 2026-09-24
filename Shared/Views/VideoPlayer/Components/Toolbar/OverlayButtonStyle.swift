//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct OverlayMenuStyle: MenuStyle {

        func makeBody(configuration: Configuration) -> some View {
            Menu(configuration)
                .menuStyle(.button)
                .buttonStyle(OverlayButtonStyle(isInBar: true, isMenu: true))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.primary, .secondary)
        }
    }

    struct OverlayBarButtonStyleModifier: ViewModifier {

        func body(content: Content) -> some View {
            content
                .font(.system(size: UIDevice.isTV ? 30 : 20, weight: .semibold))
                .buttonStyle(OverlayButtonStyle(isInBar: true))
                #if os(iOS)
                .if(UIDevice.supportsLiquidGlass) { view in
                    view
                        .backport
                        .glassEffect(.regular.interactive(true), in: .capsule)
                }
                #endif
        }
    }

    struct OverlayButtonStyle: ButtonStyle {

        private static let padding: CGFloat = 8

        @Environment(\.isEnabled)
        private var isEnabled
        @Environment(\.isFocused)
        private var isFocused

        @Environment(ViewState.self)
        private var viewState

        @State
        private var interactionID = UUID()

        var isInBar: Bool = false
        var isMenu: Bool = false

        private var labelSize: CGFloat? {
            isInBar && UIDevice.isTV ? Toolbar.buttonSize - 2 * Self.padding : nil
        }

        private var interaction: ViewState.Interaction {
            isMenu ? .menu(interactionID) : .button(interactionID)
        }

        func makeBody(configuration: Configuration) -> some View {
            styledLabel(configuration)
                .onChange(of: configuration.isPressed) {
                    // Button menus remain pressed through their nested menu hierarchy.
                    viewState.setInteraction(interaction, active: configuration.isPressed)
                }
                .onDisappear {
                    viewState.setInteraction(interaction, active: false)
                }
        }

        private func label(_ configuration: Configuration) -> some View {
            configuration.label
                .foregroundStyle(isEnabled ? isFocused ? AnyShapeStyle(Color.black) : AnyShapeStyle(HierarchicalShapeStyle.primary) :
                    AnyShapeStyle(Color.gray)
                )
                .labelStyle(.iconOnly)
                // Menu's outer frame does not size the styled label or its focus surface.
                .frame(width: labelSize, height: labelSize)
                .contentTransition(.symbolEffect(.replace))
                .contentShape(Rectangle())
        }

        @ViewBuilder
        private func styledLabel(_ configuration: Configuration) -> some View {
            if #available(iOS 26.0, tvOS 26.0, *), UIDevice.supportsLiquidGlass {
                if isInBar, !UIDevice.isTV {
                    // The bar supplies one glass surface for all of its buttons.
                    label(configuration)
                        .padding(Self.padding)
                        .contentShape(Rectangle())
                } else {
                    label(configuration)
                        .padding(Self.padding)
                        .glassEffect(.regular.tint(isFocused ? .white : nil).interactive(isEnabled), in: .circle)
                }
            } else {
                legacyLabel(configuration)
            }
        }

        private func legacyLabel(_ configuration: Configuration) -> some View {
            label(configuration)
                .scaleEffect(configuration.isPressed ? 0.8 : 1)
                .animation(.bouncy(duration: 0.25, extraBounce: 0.25), value: configuration.isPressed)
                .padding(Self.padding / 2)
                .animation(nil, value: configuration.isPressed)
                .background {
                    Circle()
                        .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.25 : isFocused ? 1 : 0))
                        .scaleEffect(configuration.isPressed ? 1 : 0.9)
                }
                .animation(.linear(duration: 0.1).delay(configuration.isPressed ? 0.2 : 0), value: configuration.isPressed)
                .padding(Self.padding / 2)
                #if os(tvOS)
                .backport
                .glassEffect(.regular.tint(isFocused ? .white : nil), in: .circle)
                #endif
        }
    }
}
