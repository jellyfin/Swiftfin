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
        private var didLongPress = false
        @State
        private var didSwipe = false
        @State
        private var pressedCommand: GeneralCommandType?
        @State
        private var swipeAnchor: CGSize = .zero

        let send: (GeneralCommandType) -> Void

        private static let cornerRadius: CGFloat = 32
        private static let swipeStep: CGFloat = 60

        private func command(at point: CGPoint, in size: CGSize) -> GeneralCommandType {
            let x = point.x - size.width / 2
            let y = point.y - size.height / 2
            let radius = min(size.width, size.height) / 2

            if (x * x + y * y).squareRoot() < radius * 0.4 {
                return .select
            }

            if abs(x) > abs(y) {
                return x > 0 ? .moveRight : .moveLeft
            }

            return y > 0 ? .moveDown : .moveUp
        }

        private func emitSwipes(for translation: CGSize) {
            let horizontal = translation.width - swipeAnchor.width
            let vertical = translation.height - swipeAnchor.height

            if abs(horizontal) > abs(vertical) {
                guard abs(horizontal) >= Self.swipeStep else { return }

                didSwipe = true
                pressedCommand = nil
                send(horizontal > 0 ? .moveRight : .moveLeft)
                swipeAnchor.width += horizontal > 0 ? Self.swipeStep : -Self.swipeStep
            } else {
                guard abs(vertical) >= Self.swipeStep else { return }

                didSwipe = true
                pressedCommand = nil
                send(vertical > 0 ? .moveDown : .moveUp)
                swipeAnchor.height += vertical > 0 ? Self.swipeStep : -Self.swipeStep
            }
        }

        @ViewBuilder
        private func directionalKey(
            _ command: GeneralCommandType,
            systemImage: String,
            alignment: Alignment
        ) -> some View {
            Image(systemName: systemImage)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(pressedCommand == command ? Color.primary : Color.secondary)
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        }

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .fill(Color.secondarySystemBackground)

                directionalKey(.moveUp, systemImage: "chevron.up", alignment: .top)
                directionalKey(.moveDown, systemImage: "chevron.down", alignment: .bottom)
                directionalKey(.moveLeft, systemImage: "chevron.left", alignment: .leading)
                directionalKey(.moveRight, systemImage: "chevron.right", alignment: .trailing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isEnabled ? 1 : 0.5)
            .animation(.linear(duration: 0.1), value: pressedCommand)
            .overlay {
                GeometryReader { proxy in
                    Color.clear
                        .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if !didSwipe {
                                        pressedCommand = command(at: value.startLocation, in: proxy.size)
                                    }

                                    emitSwipes(for: value.translation)
                                }
                                .onEnded { _ in
                                    if !didSwipe, !didLongPress, let pressedCommand {
                                        send(pressedCommand)
                                        UIDevice.impact(.light)
                                    }

                                    didLongPress = false
                                    didSwipe = false
                                    pressedCommand = nil
                                    swipeAnchor = .zero
                                }
                        )
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    guard !didSwipe else { return }

                                    didLongPress = true
                                    send(.toggleContextMenu)
                                    UIDevice.impact(.medium)
                                }
                        )
                }
            }
            .padding(8)
        }
    }
}
