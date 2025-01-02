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

// state, point, velocity, translation
typealias PanGestureHandler = (UIGestureRecognizer.State, UnitPoint, CGFloat, CGFloat) -> Void
// state, point, scale
typealias PinchGestureHandler = (UIGestureRecognizer.State, UnitPoint, CGFloat) -> Void
// point, direction, amount
typealias SwipeGestureHandler = (UnitPoint, Bool, Int) -> Void
// point, amount
typealias TapGestureHandler = (UnitPoint, Int) -> Void

struct GestureView: UIViewRepresentable {

    private var onHorizontalPan: PanGestureHandler?
    private var onHorizontalSwipe: SwipeGestureHandler?
    private var onLongPress: ((UnitPoint) -> Void)?
    private var onPinch: PinchGestureHandler?
    private var onTap: TapGestureHandler?
    private var onDoubleTouch: TapGestureHandler?
    private var onVerticalPan: PanGestureHandler?

    private var longPressMinimumDuration: TimeInterval
    private var samePointPadding: CGFloat
    private var samePointTimeout: TimeInterval
    private var swipeTranslation: CGFloat
    private var swipeVelocity: CGFloat
    private var sameSwipeDirectionTimeout: TimeInterval

    func makeUIView(context: Context) -> UIGestureView {
        UIGestureView(
            onHorizontalPan: onHorizontalPan,
            onHorizontalSwipe: onHorizontalSwipe,
            onLongPress: onLongPress,
            onPinch: onPinch,
            onTap: onTap,
            onDoubleTouch: onDoubleTouch,
            onVerticalPan: onVerticalPan,
            longPressMinimumDuration: longPressMinimumDuration,
            samePointPadding: samePointPadding,
            samePointTimeout: samePointTimeout,
            swipeTranslation: swipeTranslation,
            swipeVelocity: swipeVelocity,
            sameSwipeDirectionTimeout: sameSwipeDirectionTimeout
        )
    }

    func updateUIView(_ uiView: UIGestureView, context: Context) {}
}

extension GestureView {

    init() {
        self.init(
            longPressMinimumDuration: 0,
            samePointPadding: 0,
            samePointTimeout: 0,
            swipeTranslation: 0,
            swipeVelocity: 0,
            sameSwipeDirectionTimeout: 0
        )
    }

    func onHorizontalPan(_ action: @escaping PanGestureHandler) -> Self {
        copy(modifying: \.onHorizontalPan, with: action)
    }

    func onHorizontalSwipe(
        translation: CGFloat,
        velocity: CGFloat,
        sameSwipeDirectionTimeout: TimeInterval = 0,
        _ action: @escaping SwipeGestureHandler
    ) -> Self {
        copy(modifying: \.swipeTranslation, with: translation)
            .copy(modifying: \.swipeVelocity, with: velocity)
            .copy(modifying: \.sameSwipeDirectionTimeout, with: sameSwipeDirectionTimeout)
            .copy(modifying: \.onHorizontalSwipe, with: action)
    }

    func onPinch(_ action: @escaping PinchGestureHandler) -> Self {
        copy(modifying: \.onPinch, with: action)
    }

    func onTap(
        samePointPadding: CGFloat,
        samePointTimeout: TimeInterval,
        _ action: @escaping TapGestureHandler
    ) -> Self {
        copy(modifying: \.samePointPadding, with: samePointPadding)
            .copy(modifying: \.samePointTimeout, with: samePointTimeout)
            .copy(modifying: \.onTap, with: action)
    }

    func onDoubleTouch(_ action: @escaping TapGestureHandler) -> Self {
        copy(modifying: \.onDoubleTouch, with: action)
    }

    func onLongPress(minimumDuration: TimeInterval, _ action: @escaping (UnitPoint) -> Void) -> Self {
        copy(modifying: \.longPressMinimumDuration, with: minimumDuration)
            .copy(modifying: \.onLongPress, with: action)
    }

    func onVerticalPan(_ action: @escaping PanGestureHandler) -> Self {
        copy(modifying: \.onVerticalPan, with: action)
    }
}

class UIGestureView: UIView {

    private let onHorizontalPan: PanGestureHandler?
    private let onHorizontalSwipe: SwipeGestureHandler?
    private let onLongPress: ((UnitPoint) -> Void)?
    private let onPinch: PinchGestureHandler?
    private let onTap: TapGestureHandler?
    private let onDoubleTouch: TapGestureHandler?
    private let onVerticalPan: PanGestureHandler?

    private let longPressMinimumDuration: TimeInterval
    private let samePointPadding: CGFloat
    private let samePointTimeout: TimeInterval
    private let swipeTranslation: CGFloat
    private let swipeVelocity: CGFloat
    private var sameSwipeDirectionTimeout: TimeInterval

    private var hasSwiped: Bool = false
    private var lastSwipeDirection: Bool?
    private var lastTouchLocation: CGPoint?
    private var multiTapWorkItem: DispatchWorkItem?
    private var sameSwipeWorkItem: DispatchWorkItem?
    private var multiTapAmount: Int = 0
    private var sameSwipeAmount: Int = 0

    init(
        onHorizontalPan: PanGestureHandler?,
        onHorizontalSwipe: SwipeGestureHandler?,
        onLongPress: ((UnitPoint) -> Void)?,
        onPinch: PinchGestureHandler?,
        onTap: TapGestureHandler?,
        onDoubleTouch: TapGestureHandler?,
        onVerticalPan: PanGestureHandler?,
        longPressMinimumDuration: TimeInterval,
        samePointPadding: CGFloat,
        samePointTimeout: TimeInterval,
        swipeTranslation: CGFloat,
        swipeVelocity: CGFloat,
        sameSwipeDirectionTimeout: TimeInterval
    ) {
        self.onHorizontalPan = onHorizontalPan
        self.onHorizontalSwipe = onHorizontalSwipe
        self.onLongPress = onLongPress
        self.onPinch = onPinch
        self.onTap = onTap
        self.onDoubleTouch = onDoubleTouch
        self.onVerticalPan = onVerticalPan
        self.longPressMinimumDuration = longPressMinimumDuration
        self.samePointPadding = samePointPadding
        self.samePointTimeout = samePointTimeout
        self.swipeTranslation = swipeTranslation
        self.swipeVelocity = swipeVelocity
        self.sameSwipeDirectionTimeout = sameSwipeDirectionTimeout
        super.init(frame: .zero)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPerformPinch))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didPerformTap))
        let doubleTouchGesture = UITapGestureRecognizer(target: self, action: #selector(didPerformDoubleTouch))
        doubleTouchGesture.numberOfTouchesRequired = 2
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didPerformLongPress))
        longPressGesture.minimumPressDuration = longPressMinimumDuration
        let verticalPanGesture = PanDirectionGestureRecognizer(
            direction: .vertical,
            target: self,
            action: #selector(didPerformVerticalPan)
        )
        let horizontalPanGesture = PanDirectionGestureRecognizer(
            direction: .horizontal,
            target: self,
            action: #selector(didPerformHorizontalPan)
        )

        addGestureRecognizer(pinchGesture)
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(doubleTouchGesture)
        addGestureRecognizer(longPressGesture)
        addGestureRecognizer(verticalPanGesture)
        addGestureRecognizer(horizontalPanGesture)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didPerformHorizontalPan(_ gestureRecognizer: PanDirectionGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self).x
        let unitPoint = gestureRecognizer.unitPoint(in: self)
        let velocity = gestureRecognizer.velocity(in: self).x

        onHorizontalPan?(gestureRecognizer.state, unitPoint, velocity, translation)

        if !hasSwiped,
           abs(translation) >= swipeTranslation,
           abs(velocity) >= swipeVelocity
        {
            didPerformSwipe(unitPoint: unitPoint, direction: translation > 0)

            hasSwiped = true
        }

        if gestureRecognizer.state == .ended {
            hasSwiped = false
        }
    }

    private func didPerformSwipe(unitPoint: UnitPoint, direction: Bool) {

        if lastSwipeDirection == direction {
            sameSwipeOccurred(unitPoint: unitPoint, direction: direction)
            onHorizontalSwipe?(unitPoint, direction, sameSwipeAmount)
        } else {
            sameSwipeOccurred(unitPoint: unitPoint, direction: direction)
            onHorizontalSwipe?(unitPoint, direction, 1)
        }
    }

    private func sameSwipeOccurred(unitPoint: UnitPoint, direction: Bool) {
        guard sameSwipeDirectionTimeout > 0 else { return }
        lastSwipeDirection = direction

        sameSwipeAmount += 1

        sameSwipeWorkItem?.cancel()
        let task = DispatchWorkItem {
            self.sameSwipeAmount = 0
            self.lastSwipeDirection = nil
        }

        sameSwipeWorkItem = task

        DispatchQueue.main.asyncAfter(deadline: .now() + sameSwipeDirectionTimeout, execute: task)
    }

    @objc
    private func didPerformLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard let onLongPress, gestureRecognizer.state == .began else { return }
        let unitPoint = gestureRecognizer.unitPoint(in: self)

        onLongPress(unitPoint)
    }

    @objc
    private func didPerformPinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard let onPinch else { return }
        let unitPoint = gestureRecognizer.unitPoint(in: self)

        onPinch(gestureRecognizer.state, unitPoint, gestureRecognizer.scale)
    }

    @objc
    private func didPerformTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let onTap else { return }
        let location = gestureRecognizer.location(in: self)
        let unitPoint = gestureRecognizer.unitPoint(in: self)

        if let lastTouchLocation, lastTouchLocation.isNear(lastTouchLocation, padding: samePointPadding) {
            multiTapOccurred(at: location)
            onTap(unitPoint, multiTapAmount)
        } else {
            multiTapOccurred(at: location)
            onTap(unitPoint, 1)
        }
    }

    @objc
    private func didPerformDoubleTouch(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let onDoubleTouch else { return }
        let unitPoint = gestureRecognizer.unitPoint(in: self)

        onDoubleTouch(unitPoint, 1)
    }

    @objc
    private func didPerformVerticalPan(_ gestureRecognizer: PanDirectionGestureRecognizer) {
        guard let onVerticalPan else { return }
        let translation = gestureRecognizer.translation(in: self).y
        let unitPoint = gestureRecognizer.unitPoint(in: self)
        let velocity = gestureRecognizer.velocity(in: self).y

        onVerticalPan(gestureRecognizer.state, unitPoint, velocity, translation)
    }

    private func multiTapOccurred(at location: CGPoint) {
        guard samePointTimeout > 0 else { return }
        lastTouchLocation = location

        multiTapAmount += 1

        multiTapWorkItem?.cancel()
        let task = DispatchWorkItem {
            self.multiTapAmount = 0
            self.lastTouchLocation = nil
        }

        multiTapWorkItem = task

        DispatchQueue.main.asyncAfter(deadline: .now() + samePointTimeout, execute: task)
    }
}
