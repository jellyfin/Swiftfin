//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.UIVideoPlayerContainerViewController.SupplementContainerView {

    #if os(tvOS)
    struct SupplementTitleButtonStyle: ButtonStyle {

        @Default(.isLiquidGlassEnabled)
        private var isLiquidGlassEnabled

        @Environment(\.isFocused)
        private var isFocused
        @Environment(\.isSelected)
        private var isSelected

        @ViewBuilder
        func makeBody(configuration: Configuration) -> some View {
            if #available(tvOS 26.0, *), isLiquidGlassEnabled {
                tvOSGlassBody(configuration)
            } else {
                legacyBody(configuration)
            }
        }

        private func baseLabel(_ configuration: Configuration) -> some View {
            configuration.label
                .font(.body)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 56)
        }

        @available(tvOS 26.0, *)
        private func tvOSGlassBody(_ configuration: Configuration) -> some View {
            baseLabel(configuration)
                .foregroundStyle(isSelected ? .black : .white)
                .glassEffect(
                    .regular
                        .tint(isSelected ? .white : nil)
                        .interactive(isFocused),
                    in: Capsule()
                )
                .opacity(inactiveSelectedOpacity)
                .animation(.easeInOut(duration: 0.1), value: isFocused)
                .animation(.easeInOut(duration: 0.1), value: isSelected)
        }

        private func legacyBody(_ configuration: Configuration) -> some View {
            baseLabel(configuration)
                .foregroundStyle(isSelected ? .black : .white)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.white)
                    } else {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                }
                .clipShape(Capsule())
                .opacity(inactiveSelectedOpacity)
                .scaleEffect(isFocused ? 1.06 : 1)
                .shadow(color: isFocused ? .black.opacity(0.5) : .clear, radius: isFocused ? 10 : 0)
                .animation(.easeInOut(duration: 0.1), value: isFocused)
                .animation(.easeInOut(duration: 0.1), value: isSelected)
        }

        private var inactiveSelectedOpacity: Double {
            isSelected && !isFocused ? 0.72 : 1
        }
    }
    #else
    struct SupplementTitleButtonStyle: PrimitiveButtonStyle {

        @Default(.isLiquidGlassEnabled)
        private var isLiquidGlassEnabled

        @Environment(\.isEnabled)
        private var isEnabled
        @Environment(\.isSelected)
        private var isSelected

        @State
        private var isPressed = false

        @ViewBuilder
        func makeBody(configuration: Configuration) -> some View {
            if #available(iOS 26.0, *), isLiquidGlassEnabled {
                iOSGlassBody(configuration)
            } else {
                legacyBody(configuration)
            }
        }

        private func baseLabel(_ configuration: Configuration) -> some View {
            configuration.label
                .font(.body)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .frame(minHeight: 36)
        }

        private func legacyBody(_ configuration: Configuration) -> some View {
            pressableBody(
                baseLabel(configuration)
                    .foregroundStyle(isSelected ? .black : .white)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Color.white)
                        } else {
                            Capsule()
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .clipShape(Capsule()),
                configuration: configuration
            )
        }

        @available(iOS 26.0, *)
        private func iOSGlassBody(_ configuration: Configuration) -> some View {
            pressableBody(
                baseLabel(configuration)
                    .foregroundStyle(isSelected ? .black : .white)
                    .glassEffect(
                        .regular
                            .tint(isSelected ? .white : nil),
                        in: Capsule()
                    ),
                configuration: configuration
            )
        }

        private func pressableBody(
            _ content: some View,
            configuration: Configuration
        ) -> some View {
            content
                .contentShape(Capsule())
                .onTapGesture {
                    configuration.trigger()
                }
                .onLongPressGesture(minimumDuration: 0.01) {} onPressingChanged: { newValue in
                    if !newValue, isPressed, isEnabled {
                        UIDevice.impact(.light)
                    }

                    isPressed = newValue
                }
                .scaleEffect(isPressed ? 0.9 : 1)
                .animation(.bouncy(duration: 0.4), value: isPressed)
                .opacity(isPressed ? 0.6 : 1)
                .animation(.easeInOut(duration: 0.1), value: isSelected)
        }
    }
    #endif
}
