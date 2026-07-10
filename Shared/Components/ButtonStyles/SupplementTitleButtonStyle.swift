//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.UIVideoPlayerContainerViewController.SupplementContainerView {

    #if os(tvOS)
    struct SupplementTitleButtonStyle: ButtonStyle {

        @Environment(\.isFocused)
        private var isFocused
        @Environment(\.isSelected)
        private var isSelected

        func makeBody(configuration: Configuration) -> some View {
            baseLabel(configuration)
                .foregroundStyle(isSelected ? .black : .white)
                .opacity(inactiveSelectedOpacity)
                .scaleEffect(isFocused ? 1.06 : 1)
                .shadow(color: isFocused ? .black.opacity(0.5) : .clear, radius: isFocused ? 10 : 0)
                .animation(.easeInOut(duration: 0.1), value: isFocused)
                .animation(.easeInOut(duration: 0.1), value: isSelected)
        }

        private func baseLabel(_ configuration: Configuration) -> some View {
            configuration.label
                .font(.body)
                .fontWeight(.semibold)
                .labelStyle(
                    CapsuleLabelStyle(
                        insets: .init(vertical: 8, horizontal: 16),
                        tint: isSelected ? .white : nil,
                        isInteractive: isFocused
                    )
                )
        }

        private var inactiveSelectedOpacity: Double {
            isSelected && !isFocused ? 0.72 : 1
        }
    }
    #else
    struct SupplementTitleButtonStyle: PrimitiveButtonStyle {

        @Environment(\.isEnabled)
        private var isEnabled
        @Environment(\.isSelected)
        private var isSelected

        @State
        private var isPressed = false

        func makeBody(configuration: Configuration) -> some View {
            pressableBody(
                baseLabel(configuration)
                    .foregroundStyle(isSelected ? .black : .white),
                configuration: configuration
            )
        }

        private func baseLabel(_ configuration: Configuration) -> some View {
            configuration.label
                .font(.body)
                .fontWeight(.semibold)
                .labelStyle(
                    CapsuleLabelStyle(
                        insets: .init(vertical: 5, horizontal: 10),
                        tint: isSelected ? .white : nil
                    )
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
