//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct OverlayButtonStyle: ButtonStyle {

        @Environment(\.isEnabled)
        private var isEnabled
        @Environment(\.isFocused)
        private var isFocused

        let onPressed: (Bool) -> Void

        @ViewBuilder
        func makeBody(configuration: Configuration) -> some View {
            #if os(tvOS)
            tvOSBody(configuration)
            #else
            iOSBody(configuration)
            #endif
        }

        #if os(iOS)
        private func iOSBody(_ configuration: Configuration) -> some View {
            configuration.label
                .foregroundStyle(isEnabled ? isFocused ? AnyShapeStyle(Color.black) : AnyShapeStyle(HierarchicalShapeStyle.primary) :
                    AnyShapeStyle(Color.gray)
                )
                .labelStyle(.iconOnly)
                .contentShape(Rectangle())
                .scaleEffect(
                    configuration.isPressed ? 0.8 : 1
                )
                .animation(.bouncy(duration: 0.25, extraBounce: 0.25), value: configuration.isPressed)
                .padding(UIDevice.isTV ? 12 : 4)
                .animation(nil, value: configuration.isPressed)
                .background {
                    Circle()
                        .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.25 : isFocused ? 1 : 0))
                        .scaleEffect(configuration.isPressed ? 1 : 0.9)
                }
                .animation(.linear(duration: 0.1).delay(configuration.isPressed ? 0.2 : 0), value: configuration.isPressed)
                .padding(4)
                .backport
                .onChange(of: configuration.isPressed) { _, newValue in
                    onPressed(newValue)
                }
        }
        #endif

        #if os(tvOS)
        private func tvOSBody(_ configuration: Configuration) -> some View {
            configuration.label
                .foregroundStyle(foregroundStyle)
                .labelStyle(.iconOnly)
                .font(.body)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 56)
                .contentShape(Circle())
                .background {
                    if isFocused {
                        Circle()
                            .fill(Color.white)
                    } else {
                        Circle()
                            .fill(Material.thin.tinted(.white.opacity(0.2)))
                    }
                }
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
                .clipShape(Circle())
                .scaleEffect(configuration.isPressed ? 0.90 : isFocused ? 1.1 : 1)
                .shadow(color: isFocused ? .black.opacity(0.5) : .clear, radius: isFocused ? 10 : 0)
                .animation(.linear(duration: 0.1), value: isFocused)
                .animation(.bouncy(duration: 0.25, extraBounce: 0.25), value: configuration.isPressed)
                .backport
                .onChange(of: configuration.isPressed) { _, newValue in
                    onPressed(newValue)
                }
        }

        private var foregroundStyle: AnyShapeStyle {
            guard isEnabled else {
                return AnyShapeStyle(Color.gray)
            }

            return AnyShapeStyle(isFocused ? Color.black : Color.white)
        }
        #endif
    }
}
