//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

struct GestureView: UIViewRepresentable {

    private var onPinch: ((UIGestureRecognizer.State, CGFloat) -> Void)?
    private var onTap: ((UnitPoint, Int) -> Void)?
    private var samePointPadding: CGFloat = 0
    private var onVerticalPan: ((UnitPoint, CGPoint) -> Void)?
    private var onHorizontalPan: ((UIGestureRecognizer.State, UnitPoint, CGFloat, CGFloat) -> Void)?
    private var onHorizontalSwipe: ((CGFloat) -> Void)?
    private var swipeTranslation: CGFloat
    private var swipeVelocity: CGFloat

    func makeUIView(context: Context) -> UIGestureView {
        UIGestureView(
            onPinch: onPinch,
            onTap: onTap,
            onVerticalPan: onVerticalPan,
            onHorizontalPan: onHorizontalPan,
            onHorizontalSwipe: onHorizontalSwipe,
            swipeTranslation: swipeTranslation,
            swipeVelocity: swipeVelocity
        )
    }

    func updateUIView(_ uiView: UIGestureView, context: Context) {}
}

extension GestureView {

    func onPinch(_ action: @escaping (UIGestureRecognizer.State, CGFloat) -> Void) -> Self {
        copy(modifying: \.onPinch, with: action)
    }

    func onTap(samePointPadding: CGFloat = 0, _ action: @escaping ((UnitPoint, Int) -> Void)) -> Self {
        copy(modifying: \.samePointPadding, with: samePointPadding)
            .copy(modifying: \.onTap, with: action)
    }

    func onVerticalPan(_ action: @escaping (UnitPoint, CGPoint) -> Void) -> Self {
        copy(modifying: \.onVerticalPan, with: action)
    }

    func onHorizontalPan(_ action: @escaping (UIGestureRecognizer.State, UnitPoint, CGFloat, CGFloat) -> Void) -> Self {
        copy(modifying: \.onHorizontalPan, with: action)
    }
    
    func onHorizontalSwipe(
        translation: CGFloat = 0,
        velocity: CGFloat = 0,
        _ action: @escaping (CGFloat) -> Void) -> Self {
            copy(modifying: \.swipeTranslation, with: translation)
                .copy(modifying: \.swipeVelocity, with: velocity)
                .copy(modifying: \.onHorizontalSwipe, with: action)
    }
}

class UIGestureView: UIView {

    private let onPinch: ((UIGestureRecognizer.State, CGFloat) -> Void)?
    private let onTap: ((UnitPoint, Int) -> Void)?
    private let samePointPadding: CGFloat
    private let onVerticalPan: ((UnitPoint, CGPoint) -> Void)?
    private let onHorizontalPan: ((UIGestureRecognizer.State, UnitPoint, CGFloat, CGFloat) -> Void)?
    private let onHorizontalSwipe: ((CGFloat) -> Void)?
    private let swipeTranslation: CGFloat
    private let swipeVelocity: CGFloat
    
    private var multiTapAmount: Int = 0
    private var multiTapTimer: Timer?
    private var lastTouchLocation: CGPoint?

    init(
        onPinch: ((UIGestureRecognizer.State, CGFloat) -> Void)?,
        onTap: ((UnitPoint, Int) -> Void)?,
        samePointPadding: CGFloat,
        onVerticalPan: ((UnitPoint, CGPoint) -> Void)?,
        onHorizontalPan: ((UIGestureRecognizer.State, UnitPoint, CGFloat, CGFloat) -> Void)?,
        onHorizontalSwipe: ((CGFloat) -> Void)?,
        swipeTranslation: CGFloat,
        swipeVelocity: CGFloat
    ) {
        self.onPinch = onPinch
        self.onTap = onTap
        self.samePointPadding = samePointPadding
        self.onVerticalPan = onVerticalPan
        self.onHorizontalPan = onHorizontalPan
        self.onHorizontalSwipe = onHorizontalSwipe
        self.swipeTranslation = swipeTranslation
        self.swipeVelocity = swipeVelocity
        super.init(frame: .zero)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPerformPinch(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didPerformTap(_:)))
        let verticalPanGesture = PanDirectionGestureRecognizer(
            direction: .vertical,
            target: self,
            action: #selector(didPerformVerticalPan(_:))
        )
        let horizontalPanGesture = PanDirectionGestureRecognizer(
            direction: .horizontal,
            target: self,
            action: #selector(didPerformHorizontalPan(_:))
        )

        addGestureRecognizer(pinchGesture)
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(verticalPanGesture)
        addGestureRecognizer(horizontalPanGesture)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didPerformPinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        onPinch?(gestureRecognizer.state, gestureRecognizer.scale)
    }

    @objc
    private func didPerformTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let onTap else { return }
        let location = gestureRecognizer.location(in: self)
        let unitPoint: UnitPoint = .init(x: location.x / frame.width, y: location.y / frame.height)
        
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
        let location = gestureRecognizer.location(in: self)
        let unitPoint: UnitPoint = .init(x: location.x / frame.width, y: location.y / frame.height)
        let translation = gestureRecognizer.translation(in: self)
        onVerticalPan(unitPoint, translation)
    }

    @objc
    private func didPerformHorizontalPan(_ gestureRecognizer: PanDirectionGestureRecognizer) {
        guard let onHorizontalPan else { return }
        let location = gestureRecognizer.location(in: self)
        let unitPoint: UnitPoint = .init(x: location.x / frame.width, y: location.y / frame.height)
        let translation = gestureRecognizer.translation(in: self).x
        let velocity = gestureRecognizer.velocity(in: self).x
        onHorizontalPan(gestureRecognizer.state, unitPoint, velocity, translation)
        
        
    }
    
    private func multiTapOccurred(at location: CGPoint) {
        lastTouchLocation = location
        
        multiTapTimer?.invalidate()
        multiTapTimer = Timer.scheduledTimer(
            timeInterval: 0.5,
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
