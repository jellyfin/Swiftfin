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

        private let cornerRadius: CGFloat = 32
        private let swipeStep: CGFloat = 60

        let send: (GeneralCommandType) -> Void

        private func command(at point: CGPoint, in size: CGSize) -> GeneralCommandType {
            let x = point.x - size.width / 2
            let y = point.y - size.height / 2
            let radius = min(size.width, size.height) / 2

            if hypot(x, y) < radius * 0.4 {
                return .select
            }

            if abs(x) > abs(y) {
                return x > 0 ? .moveRight : .moveLeft
            }

            return y > 0 ? .moveDown : .moveUp
        }

        private func tap(at location: CGPoint, in size: CGSize) {
            let command = command(at: location, in: size)

            pressedCommand = command
            send(command)
            UIDevice.impact(.light)

            Task {
                try? await Task.sleep(for: .milliseconds(150))
                pressedCommand = nil
            }
        }

        private func pan(translation: CGPoint, state: UIGestureRecognizer.State) {
            guard state == .began || state == .changed else {
                pressedCommand = nil
                swipeAnchor = .zero
                return
            }

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

        private func longPress(state: UIGestureRecognizer.State) {
            guard state == .began else { return }

            send(.toggleContextMenu)
            UIDevice.impact(.medium)
        }

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
                RoundedRectangle(cornerRadius: cornerRadius)
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
                                tap(at: location, in: proxy.size)
                            }
                        )
                        .environment(
                            \.panAction,
                            PanAction { translation, _, _, _, state in
                                pan(translation: translation, state: state)
                            }
                        )
                        .environment(
                            \.longPressAction,
                            LongPressAction { _, _, state in
                                longPress(state: state)
                            }
                        )
                        .allowsHitTesting(isEnabled)
                }
            }
            .padding(8)
        }
    }
}
