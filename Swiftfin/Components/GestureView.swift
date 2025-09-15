//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Logging
import SwiftUI

// TODO: figure out this directional response stuff
extension EnvironmentValues {

    @Entry
    var panGestureDirection: Direction = .all
}

struct GestureView: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        view.addGestureRecognizer(context.coordinator.longPressGesture)
        view.addGestureRecognizer(context.coordinator.panGesture)
        view.addGestureRecognizer(context.coordinator.pinchGesture)
        view.addGestureRecognizer(context.coordinator.tapGesture)
        view.addGestureRecognizer(context.coordinator.doubleTouchGesture)

        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {

        context.coordinator.longPressAction = context.environment.longPressAction
        context.coordinator.panAction = context.environment.panAction
        context.coordinator.pinchAction = context.environment.pinchAction
        context.coordinator.tapAction = context.environment.tapGestureAction

        context.coordinator.panGesture.direction = context.environment.panGestureDirection
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {

        lazy var doubleTouchGesture: UITapGestureRecognizer! = {
            let recognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(handleTap)
            )
            recognizer.numberOfTouchesRequired = 2
            return recognizer
        }()

        lazy var longPressGesture: UILongPressGestureRecognizer! = {
            let recognizer = UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleLongPress)
            )
            recognizer.minimumPressDuration = 1.2
            return recognizer
        }()

        lazy var panGesture: DirectionalPanGestureRecognizer! = {
            .init(
                direction: .allButDown,
                target: self,
                action: #selector(handlePan)
            )
        }()

        lazy var pinchGesture: UIPinchGestureRecognizer! = {
            .init(
                target: self,
                action: #selector(handlePinch)
            )
        }()

        lazy var tapGesture: UITapGestureRecognizer! = {
            .init(
                target: self,
                action: #selector(handleTap)
            )
        }()

        var longPressAction: LongPressAction? {
            didSet { longPressGesture.isEnabled = longPressAction != nil }
        }

        var panAction: PanAction? {
            didSet { panGesture.isEnabled = panAction != nil }
        }

        var pinchAction: PinchAction? {
            didSet { pinchGesture.isEnabled = pinchAction != nil }
        }

        var tapAction: TapAction? {
            didSet {
                doubleTouchGesture.isEnabled = tapAction != nil
                tapGesture.isEnabled = tapAction != nil
            }
        }

        private var didSwipe = false

        @objc
        func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let view = gesture.view else { return }

            let location = gesture.location(in: view)
            let unitPoint = UnitPoint(
                x: location.x / view.bounds.width,
                y: location.y / view.bounds.height
            )

            longPressAction?(
                location: location,
                unitPoint: unitPoint,
                state: gesture.state
            )
        }

        @objc
        func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }

            let translation = gesture.translation(in: view)
            let velocity = gesture.velocity(in: view)
            let location = gesture.location(in: view)
            let unitPoint = UnitPoint(
                x: location.x / view.bounds.width,
                y: location.y / view.bounds.height
            )

            panAction?(
                translation: translation,
                velocity: velocity,
                location: location,
                unitPoint: unitPoint,
                state: gesture.state
            )
        }

        @objc
        func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            pinchAction?(
                scale: gesture.scale,
                velocity: gesture.velocity,
                state: gesture.state
            )
        }

        @objc
        func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }

            let location = gesture.location(in: gesture.view)
            let unitPoint = UnitPoint(
                x: location.x / view.bounds.width,
                y: location.y / view.bounds.height
            )

            tapAction?(
                location: location,
                unitPoint: unitPoint,
                count: gesture.numberOfTouches
            )
        }
    }
}
