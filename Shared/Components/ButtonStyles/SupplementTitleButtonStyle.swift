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

    struct SupplementTitleButtonStyle: ButtonStyle {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isFocused)
        private var isFocused
        @Environment(\.isSelected)
        private var isSelected
        @Environment(\.isEnabled)
        private var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .fontWeight(.semibold)
                .foregroundStyle(isFocused ? accentColor.overlayColor : isSelected ? .black : .white)
                .padding(.horizontal, UIDevice.isTV ? 12 : 10)
                .padding(.vertical, UIDevice.isTV ? 6 : 3)
                .background {
                    if isFocused || isSelected {
                        RoundedRectangle(cornerRadius: 7)
                            .foregroundStyle(isFocused ? accentColor : .white)
                    }
                }
                .overlay {
                    if !isSelected {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.white, lineWidth: UIDevice.isTV ? 6 : 4)
                    }
                }
                .mask {
                    RoundedRectangle(cornerRadius: 7)
                }
            #if os(tvOS)
                .shadow(color: isFocused ? .black.opacity(0.5) : .clear, radius: isFocused ? 10 : 0)
            #else
                .scaleEffect(
                    x: configuration.isPressed ? 0.9 : 1,
                    y: configuration.isPressed ? 0.9 : 1,
                    anchor: .init(x: 0.5, y: 0.5)
                )
                .animation(.bouncy(duration: 0.4), value: configuration.isPressed)
                .opacity(configuration.isPressed ? 0.6 : 1)
                .backport
                .onChange(of: configuration.isPressed) { _, newValue in
                    if !newValue, isEnabled {
                        UIDevice.impact(.light)
                    }
                }
            #endif
        }
    }
}
