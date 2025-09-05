//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import SwiftUI

// TODO: change swipe to directional
// TODO: figure out way for multitap near the middle be distinguished as different sides

typealias LongPressGestureHandler = (UnitPoint) -> Void
// state, point, velocity, translation
typealias PanGestureHandler = (UIGestureRecognizer.State, UnitPoint, CGFloat, CGFloat) -> Void
// state, point, scale
typealias PinchGestureHandler = (UIGestureRecognizer.State, UnitPoint, CGFloat) -> Void
// point, direction, amount
typealias SwipeGestureHandler = (UnitPoint, Direction) -> Void
// point, amount
typealias TapGestureHandler = (UnitPoint, Int) -> Void

// TODO: figure out this directional response stuff
extension EnvironmentValues {

    @Entry
    var panGestureDirection: Direction = .all
}

struct GestureView: UIViewRepresentable {

    @Environment(\.panGestureAction)
    private var panAction: PanGestureAction?
    @Environment(\.tapGestureAction)
    private var tapAction: TapGestureAction?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        view.addGestureRecognizer(context.coordinator.panGesture)
        view.addGestureRecognizer(context.coordinator.pinchGesture)
        view.addGestureRecognizer(context.coordinator.swipeGesture)
        view.addGestureRecognizer(context.coordinator.tapGesture)

        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {

        context.coordinator.panAction = context.environment.panGestureAction
        context.coordinator.pinchAction = context.environment.pinchGestureAction
        context.coordinator.tapAction = context.environment.tapGestureAction

        context.coordinator.panGesture.direction = context.environment.panGestureDirection
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {

        lazy var panGesture: DirectionalPanGestureRecognizer! = {
            DirectionalPanGestureRecognizer(
                direction: .all,
                target: self,
                action: #selector(handlePan)
            )
        }()

        lazy var pinchGesture: UIPinchGestureRecognizer! = {
            UIPinchGestureRecognizer(
                target: self,
                action: #selector(handlePinch)
            )
        }()

        lazy var swipeGesture: UISwipeGestureRecognizer = {
            UISwipeGestureRecognizer(
                target: self,
                action: #selector(handleSwipe)
            )
        }()

        lazy var tapGesture: UITapGestureRecognizer! = {
            UITapGestureRecognizer(
                target: self,
                action: #selector(handleTap)
            )
        }()

        var panAction: PanGestureAction? {
            didSet { panGesture.isEnabled = panAction != nil }
        }

        var pinchAction: PinchGestureAction? {
            didSet { pinchGesture.isEnabled = pinchAction != nil }
        }

        var swipeAction: SwipeGestureAction? {
            didSet { swipeGesture.isEnabled = swipeAction != nil }
        }

        var tapAction: TapGestureAction? {
            didSet { tapGesture.isEnabled = tapAction != nil }
        }

        @objc
        func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)
            let location = gesture.location(in: gesture.view)
            panAction?(
                point: translation,
                velocity: velocity.y,
                location: location,
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
        func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
//            let location = gesture.location(in: gesture.view)
//            guard let view = gesture.view else { return }
//
//            let unitPoint = UnitPoint(
//                x: location.x / view.bounds.width,
//                y: location.y / view.bounds.height
//            )
//            let direction: Direction
//            switch gesture.direction {
//            case .up:
//                direction = .up
//            case .down:
//                direction = .down
//            case .left:
//                direction = .left
//            case .right:
//                direction = .right
//            default:
//                return
//            }
            // Assuming a single swipe counts as 1
//            tapAction(unitPoint, 1)
        }

        @objc
        func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            guard let view = gesture.view else { return }

            let unitPoint = UnitPoint(
                x: location.x / view.bounds.width,
                y: location.y / view.bounds.height
            )
            tapAction?(
                point: unitPoint,
                count: gesture.numberOfTouches
            )
        }
    }
}

// struct GestureView: UIViewRepresentable {
//
//    private var onHorizontalPan: PanGestureHandler?
//    private var onHorizontalSwipe: SwipeGestureHandler?
//    private var onLongPress: LongPressGestureHandler?
//    private var onPinch: PinchGestureHandler?
//    private var onTap: TapGestureHandler?
//    private var onDoubleTouch: TapGestureHandler?
//    private var onVerticalPan: PanGestureHandler?
//
//    private var longPressMinimumDuration: TimeInterval
//    private var samePointPadding: CGFloat
//    private var samePointTimeout: TimeInterval
//    private var swipeTranslation: CGFloat
//    private var swipeVelocity: CGFloat
//    private var sameSwipeDirectionTimeout: TimeInterval
//
//    func makeUIView(context: Context) -> UIGestureView {
//        UIGestureView(
//            onHorizontalPan: onHorizontalPan,
//            onHorizontalSwipe: onHorizontalSwipe,
//            onLongPress: onLongPress,
//            onPinch: onPinch,
//            onTap: onTap,
//            onDoubleTouch: onDoubleTouch,
//            onVerticalPan: onVerticalPan,
//            longPressMinimumDuration: longPressMinimumDuration,
//            samePointPadding: samePointPadding,
//            samePointTimeout: samePointTimeout,
//            swipeTranslation: swipeTranslation,
//            swipeVelocity: swipeVelocity,
//            sameSwipeDirectionTimeout: sameSwipeDirectionTimeout
//        )
//    }
//
//    func updateUIView(_ uiView: UIGestureView, context: Context) {}
// }
//
// extension GestureView {
//
//    init() {
//        self.init(
//            longPressMinimumDuration: 0,
//            samePointPadding: 0,
//            samePointTimeout: 0,
//            swipeTranslation: 0,
//            swipeVelocity: 0,
//            sameSwipeDirectionTimeout: 0
//        )
//    }
//
//    func onHorizontalPan(_ action: @escaping PanGestureHandler) -> Self {
//        copy(modifying: \.onHorizontalPan, with: action)
//    }
//
//    func onHorizontalSwipe(
//        translation: CGFloat,
//        velocity: CGFloat,
//        sameSwipeDirectionTimeout: TimeInterval = 0,
//        _ action: @escaping SwipeGestureHandler
//    ) -> Self {
//        copy(modifying: \.swipeTranslation, with: translation)
//            .copy(modifying: \.swipeVelocity, with: velocity)
//            .copy(modifying: \.sameSwipeDirectionTimeout, with: sameSwipeDirectionTimeout)
//            .copy(modifying: \.onHorizontalSwipe, with: action)
//    }
//
//    func onPinch(_ action: @escaping PinchGestureHandler) -> Self {
//        copy(modifying: \.onPinch, with: action)
//    }
//
//    func onTap(
//        samePointPadding: CGFloat,
//        samePointTimeout: TimeInterval,
//        perform action: @escaping TapGestureHandler
//    ) -> Self {
////        copy(modifying: \.samePointPadding, with: samePointPadding)
////            .copy(modifying: \.samePointTimeout, with: samePointTimeout)
//        copy(modifying: \.onTap, with: action)
//    }
//
//    func onDoubleTouch(_ action: @escaping TapGestureHandler) -> Self {
//        copy(modifying: \.onDoubleTouch, with: action)
//    }
//
//    func onLongPress(minimumDuration: TimeInterval, _ action: @escaping (UnitPoint) -> Void) -> Self {
//        copy(modifying: \.longPressMinimumDuration, with: minimumDuration)
//            .copy(modifying: \.onLongPress, with: action)
//    }
//
//    func onVerticalPan(_ action: @escaping PanGestureHandler) -> Self {
//        copy(modifying: \.onVerticalPan, with: action)
//    }
// }
//
// class UIGestureView: UIView {
//
//    private let onHorizontalPan: PanGestureHandler?
//    private let onHorizontalSwipe: SwipeGestureHandler?
//    private let onLongPress: LongPressGestureHandler?
//    private let onPinch: PinchGestureHandler?
//    private let onTap: TapGestureHandler?
//    private let onDoubleTouch: TapGestureHandler?
//    private let onVerticalPan: PanGestureHandler?
//
//    private let longPressMinimumDuration: TimeInterval
//    private let samePointPadding: CGFloat
//    private let samePointTimeout: TimeInterval
//    private let swipeTranslation: CGFloat
//    private let swipeVelocity: CGFloat
//    private var sameSwipeDirectionTimeout: TimeInterval
//
//    private var hasSwiped: Bool = false
//    private var lastSwipeDirection: Direction?
//    private var lastTouchLocation: CGPoint?
//    private var multiTapWorkItem: DispatchWorkItem?
//    private var sameSwipeWorkItem: DispatchWorkItem?
//    private var multiTapAmount: Int = 0
//
//    init(
//        onHorizontalPan: PanGestureHandler?,
//        onHorizontalSwipe: SwipeGestureHandler?,
//        onLongPress: LongPressGestureHandler?,
//        onPinch: PinchGestureHandler?,
//        onTap: TapGestureHandler?,
//        onDoubleTouch: TapGestureHandler?,
//        onVerticalPan: PanGestureHandler?,
//        longPressMinimumDuration: TimeInterval,
//        samePointPadding: CGFloat,
//        samePointTimeout: TimeInterval,
//        swipeTranslation: CGFloat,
//        swipeVelocity: CGFloat,
//        sameSwipeDirectionTimeout: TimeInterval
//    ) {
//        self.onHorizontalPan = onHorizontalPan
//        self.onHorizontalSwipe = onHorizontalSwipe
//        self.onLongPress = onLongPress
//        self.onPinch = onPinch
//        self.onTap = onTap
//        self.onDoubleTouch = onDoubleTouch
//        self.onVerticalPan = onVerticalPan
//        self.longPressMinimumDuration = longPressMinimumDuration
//        self.samePointPadding = samePointPadding
//        self.samePointTimeout = samePointTimeout
//        self.swipeTranslation = swipeTranslation
//        self.swipeVelocity = swipeVelocity
//        self.sameSwipeDirectionTimeout = sameSwipeDirectionTimeout
//        super.init(frame: .zero)
//
//        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPerformPinch))
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didPerformTap))
//        let doubleTouchGesture = UITapGestureRecognizer(target: self, action: #selector(didPerformDoubleTouch))
//        doubleTouchGesture.numberOfTouchesRequired = 2
//        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didPerformLongPress))
//        longPressGesture.minimumPressDuration = longPressMinimumDuration
//
//        let verticalPanGesture = DirectionalPanGestureRecognizer(
//            direction: .vertical,
//            target: self,
//            action: #selector(didPerformVerticalPan)
//        )
//        let horizontalPanGesture = DirectionalPanGestureRecognizer(
//            direction: .horizontal,
//            target: self,
//            action: #selector(didPerformHorizontalPan)
//        )
//
//        // TODO: handle conflicts
//
//        addGestureRecognizer(pinchGesture)
//        addGestureRecognizer(tapGesture)
////        addGestureRecognizer(doubleTouchGesture)
//        addGestureRecognizer(longPressGesture)
////        addGestureRecognizer(verticalPanGesture)
////        addGestureRecognizer(horizontalPanGesture)
//    }
//
//    @available(*, unavailable)
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    @objc
//    private func didPerformHorizontalPan(_ gestureRecognizer: DirectionalPanGestureRecognizer) {
//        let translation = gestureRecognizer.translation(in: self).x
//        let unitPoint = gestureRecognizer.unitPoint(in: self)
//        let velocity = gestureRecognizer.velocity(in: self).x
//
//        onHorizontalPan?(gestureRecognizer.state, unitPoint, velocity, translation)
//
//        if !hasSwiped,
//           abs(translation) >= swipeTranslation,
//           abs(velocity) >= swipeVelocity
//        {
//            onHorizontalSwipe?(unitPoint, translation > 0 ? .right : .left)
//            hasSwiped = true
//        }
//
//        if gestureRecognizer.state == .ended {
//            hasSwiped = false
//        }
//    }
//
//    @objc
//    private func didPerformLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
//        guard let onLongPress, gestureRecognizer.state == .began else { return }
//        let unitPoint = gestureRecognizer.unitPoint(in: self)
//
//        onLongPress(unitPoint)
//    }
//
//    @objc
//    private func didPerformPinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
//        guard let onPinch else { return }
//        let unitPoint = gestureRecognizer.unitPoint(in: self)
//
//        onPinch(gestureRecognizer.state, unitPoint, gestureRecognizer.scale)
//    }
//
//    @objc
//    private func didPerformTap(_ gestureRecognizer: UITapGestureRecognizer) {
//        guard let onTap else { return }
//        let location = gestureRecognizer.location(in: self)
//        let unitPoint = gestureRecognizer.unitPoint(in: self)
//
//        if let lastTouchLocation, lastTouchLocation.isNear(lastTouchLocation, epsilon: samePointPadding) {
//            multiTapOccurred(at: location)
//            onTap(unitPoint, multiTapAmount)
//        } else {
//            multiTapOccurred(at: location)
//            onTap(unitPoint, 1)
//        }
//    }
//
//    @objc
//    private func didPerformDoubleTouch(_ gestureRecognizer: UITapGestureRecognizer) {
//        guard let onDoubleTouch else { return }
//        let unitPoint = gestureRecognizer.unitPoint(in: self)
//
//        onDoubleTouch(unitPoint, 1)
//    }
//
//    @objc
//    private func didPerformVerticalPan(_ gestureRecognizer: DirectionalPanGestureRecognizer) {
//        guard let onVerticalPan else { return }
//        let translation = gestureRecognizer.translation(in: self).y
//        let unitPoint = gestureRecognizer.unitPoint(in: self)
//        let velocity = gestureRecognizer.velocity(in: self).y
//
//        onVerticalPan(gestureRecognizer.state, unitPoint, velocity, translation)
//    }
//
//    private func multiTapOccurred(at location: CGPoint) {
//        guard samePointTimeout > 0 else { return }
//        lastTouchLocation = location
//
//        multiTapAmount += 1
//
//        multiTapWorkItem?.cancel()
//        let task = DispatchWorkItem {
//            self.multiTapAmount = 0
//            self.lastTouchLocation = nil
//        }
//
//        multiTapWorkItem = task
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + samePointTimeout, execute: task)
//    }
// }
