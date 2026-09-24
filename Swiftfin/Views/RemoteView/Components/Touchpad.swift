//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension RemoteView {

    struct Touchpad: View {

        @Environment(\.isEnabled)
        private var isEnabled

        @State
        private var pressedCommand: GeneralCommandType?
        @State
        private var swipeAnchor: CGSize = .zero

        let send: (GeneralCommandType) -> Void

        @ViewBuilder
        private func directionalKey(_ command: GeneralCommandType) -> some View {
            let alignment: Alignment = switch command {
            case .moveUp:
                .top
            case .moveDown:
                .bottom
            case .moveLeft:
                .leading
            default:
                .trailing
            }

            Image(systemName: command.systemImage)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(pressedCommand == command ? Color.primary : Color.secondary)
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        }

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.secondarySystemBackground)

                directionalKey(.moveUp)
                directionalKey(.moveDown)
                directionalKey(.moveLeft)
                directionalKey(.moveRight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isEnabled ? 1 : 0.5)
            .animation(.linear(duration: 0.1), value: pressedCommand)
            .overlay {
                GeometryReader { proxy in
                    GestureView()
                        .environment(
                            \.tapGestureAction,
                            TapAction { location, _, _ in
                                let x = location.x - proxy.size.width / 2
                                let y = location.y - proxy.size.height / 2
                                let radius = min(proxy.size.width, proxy.size.height) / 2

                                let command: GeneralCommandType = if hypot(x, y) < radius * 0.4 {
                                    .select
                                } else if abs(x) > abs(y) {
                                    x > 0 ? .moveRight : .moveLeft
                                } else {
                                    y > 0 ? .moveDown : .moveUp
                                }

                                pressedCommand = command
                                send(command)
                                UIDevice.impact(.light)

                                Task {
                                    try? await Task.sleep(for: .milliseconds(150))
                                    pressedCommand = nil
                                }
                            }
                        )
                        .environment(
                            \.panAction,
                            PanAction { translation, _, _, _, state in
                                guard state == .began || state == .changed else {
                                    pressedCommand = nil
                                    swipeAnchor = .zero
                                    return
                                }

                                let swipeStep: CGFloat = 60
                                let horizontal = translation.x - swipeAnchor.width
                                let vertical = translation.y - swipeAnchor.height
                                let isHorizontal = abs(horizontal) > abs(vertical)
                                let distance = isHorizontal ? horizontal : vertical

                                guard abs(distance) >= swipeStep else { return }

                                let command: GeneralCommandType = switch (isHorizontal, distance > 0) {
                                case (true, true):
                                    .moveRight
                                case (true, false):
                                    .moveLeft
                                case (false, true):
                                    .moveDown
                                case (false, false):
                                    .moveUp
                                }

                                if isHorizontal {
                                    swipeAnchor.width += distance > 0 ? swipeStep : -swipeStep
                                } else {
                                    swipeAnchor.height += distance > 0 ? swipeStep : -swipeStep
                                }

                                pressedCommand = command
                                send(command)
                            }
                        )
                        .environment(
                            \.longPressAction,
                            LongPressAction { _, _, state in
                                guard state == .began else { return }

                                send(.toggleContextMenu)
                                UIDevice.impact(.medium)
                            }
                        )
                        .allowsHitTesting(isEnabled)
                }
            }
            .padding(8)
        }
    }
}
