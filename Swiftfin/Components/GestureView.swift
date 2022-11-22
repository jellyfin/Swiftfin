//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import SwiftUI

// state, point, velocity, translation
typealias PanGestureHandler = (UIGestureRecognizer.State, UnitPoint, CGFloat, CGFloat) -> Void
// state, point, scale
typealias PinchGestureHandler = (UIGestureRecognizer.State, UnitPoint, CGFloat) -> Void
// point, taps
typealias TapGestureHandler = (UnitPoint, Int) -> Void

struct GestureView: UIViewRepresentable {

    private var onHorizontalPan: PanGestureHandler?
    private var onHorizontalSwipe: PanGestureHandler?
    private var onLongPress: ((UnitPoint) -> Void)?
    private var onPinch: PinchGestureHandler?
    private var onTap: TapGestureHandler?
    private var onVerticalPan: PanGestureHandler?
    
    private var longPressMinimumDuration: TimeInterval = 0
    private var samePointPadding: CGFloat = 0
    private var samePointTimeout: TimeInterval = 0
    private var swipeTranslation: CGFloat = 0
    private var swipeVelocity: CGFloat = 0

    func makeUIView(context: Context) -> UIGestureView {
        UIGestureView(
            onHorizontalPan: onHorizontalPan,
            onHorizontalSwipe: onHorizontalSwipe,
            onLongPress: onLongPress,
            onPinch: onPinch,
            onTap: onTap,
            onVerticalPan: onVerticalPan,
            longPressMinimumDuration: longPressMinimumDuration,
            samePointPadding: samePointPadding,
            samePointTimeout: samePointTimeout,
            swipeTranslation: swipeTranslation,
            swipeVelocity: swipeVelocity
        )
    }

    func updateUIView(_ uiView: UIGestureView, context: Context) {}
}

extension GestureView {
    
    func onHorizontalPan(_ action: @escaping PanGestureHandler) -> Self {
        copy(modifying: \.onHorizontalPan, with: action)
    }
    
    func onHorizontalSwipe(
        translation: CGFloat,
        velocity: CGFloat,
        _ action: @escaping PanGestureHandler
    ) -> Self {
            copy(modifying: \.swipeTranslation, with: translation)
                .copy(modifying: \.swipeVelocity, with: velocity)
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
            .copy(modifying: \.onTap, with: action)
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
    private let onHorizontalSwipe: PanGestureHandler?
    private let onLongPress: ((UnitPoint) -> Void)?
    private let onPinch: PinchGestureHandler?
    private let onTap: TapGestureHandler?
    private let onVerticalPan: PanGestureHandler?
    
    private let longPressMinimumDuration: TimeInterval
    private let samePointPadding: CGFloat
    private let samePointTimeout: TimeInterval
    private let swipeTranslation: CGFloat
    private let swipeVelocity: CGFloat
    
    private var hasSwiped: Bool = false
    private var multiTapAmount: Int = 0
    private var multiTapTimer: Timer?
    private var lastTouchLocation: CGPoint?

    init(
        onHorizontalPan: PanGestureHandler?,
        onHorizontalSwipe: PanGestureHandler?,
        onLongPress: ((UnitPoint) -> Void)?,
        onPinch: PinchGestureHandler?,
        onTap: TapGestureHandler?,
        onVerticalPan: PanGestureHandler?,
        longPressMinimumDuration: TimeInterval,
        samePointPadding: CGFloat,
        samePointTimeout: TimeInterval,
        swipeTranslation: CGFloat,
        swipeVelocity: CGFloat
    ) {
        self.onHorizontalPan = onHorizontalPan
        self.onHorizontalSwipe = onHorizontalSwipe
        self.onLongPress = onLongPress
        self.onPinch = onPinch
        self.onTap = onTap
        self.onVerticalPan = onVerticalPan
        self.longPressMinimumDuration = longPressMinimumDuration
        self.samePointPadding = samePointPadding
        self.samePointTimeout = samePointTimeout
        self.swipeTranslation = swipeTranslation
        self.swipeVelocity = swipeVelocity
        super.init(frame: .zero)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPerformPinch))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didPerformTap))
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
           abs(velocity) >= swipeVelocity {
            onHorizontalSwipe?(UIGestureRecognizer.State.ended, unitPoint, velocity, translation)
            hasSwiped = true
        }
        
        if gestureRecognizer.state == .ended {
            hasSwiped = false
        }
    }
    
    @objc
    private func didPerformLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard let onLongPress, gestureRecognizer.state == .began else { return }
        let unitPoint = gestureRecognizer.unitPoint(in: self)
        
        onLongPress(unitPoint)
    }

    @objc
    private func didPerformPinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        let unitPoint = gestureRecognizer.unitPoint(in: self)
        
        onPinch?(gestureRecognizer.state, unitPoint, gestureRecognizer.scale)
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
        
        multiTapTimer?.invalidate()
        multiTapTimer = Timer.scheduledTimer(
            timeInterval: samePointTimeout,
            target: self,
            selector: #selector(multiTapTimed),
            userInfo: nil,
            repeats: false)
        
        multiTapAmount += 1
    }
    
    @objc
    private func multiTapTimed() {
        multiTapTimer = nil
        multiTapAmount = 0
        lastTouchLocation = nil
    }
}

extension UIGestureRecognizer {
    
    func unitPoint(in view: UIView) -> UnitPoint {
        let location = location(in: view)
        return .init(x: location.x / view.frame.width, y: location.y / view.frame.height)
    }
}
