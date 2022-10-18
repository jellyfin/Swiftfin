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
    private var onVerticalPan: ((UnitPoint, CGPoint) -> Void)?
    private var onHorizontalPan: ((UIGestureRecognizer.State, UnitPoint, CGFloat, CGFloat) -> Void)?

    func makeUIView(context: Context) -> UIGestureView {
        UIGestureView(
            onPinch: onPinch,
            onTap: onTap,
            onVerticalPan: onVerticalPan,
            onHorizontalPan: onHorizontalPan
        )
    }

    func updateUIView(_ uiView: UIGestureView, context: Context) {}
}

extension GestureView {

    func onPinch(_ action: @escaping (UIGestureRecognizer.State, CGFloat) -> Void) -> Self {
        copy(modifying: \.onPinch, with: action)
    }

    func onTap(_ action: @escaping ((UnitPoint, Int) -> Void)) -> Self {
        copy(modifying: \.onTap, with: action)
    }

    func onVerticalPan(_ action: @escaping (UnitPoint, CGPoint) -> Void) -> Self {
        copy(modifying: \.onVerticalPan, with: action)
    }

    func onHorizontalPan(_ action: @escaping (UIGestureRecognizer.State, UnitPoint, CGFloat, CGFloat) -> Void) -> Self {
        copy(modifying: \.onHorizontalPan, with: action)
    }
}

class UIGestureView: UIView {

    private let onPinch: ((UIGestureRecognizer.State, CGFloat) -> Void)?
    private let onTap: ((UnitPoint, Int) -> Void)?
    private let onVerticalPan: ((UnitPoint, CGPoint) -> Void)?
    private let onHorizontalPan: ((UIGestureRecognizer.State, UnitPoint, CGFloat, CGFloat) -> Void)?
    
    private var multiTapAmount: Int = 0
    private var multiTapTimer: Timer?
    private var lastTouchLocation: CGPoint?

    init(
        onPinch: ((UIGestureRecognizer.State, CGFloat) -> Void)?,
        onTap: ((UnitPoint, Int) -> Void)?,
        onVerticalPan: ((UnitPoint, CGPoint) -> Void)?,
        onHorizontalPan: ((UIGestureRecognizer.State, UnitPoint, CGFloat, CGFloat) -> Void)?
    ) {
        self.onPinch = onPinch
        self.onTap = onTap
        self.onVerticalPan = onVerticalPan
        self.onHorizontalPan = onHorizontalPan
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
        
        if let lastTouchLocation, lastTouchLocation.isNear(lastTouchLocation, padding: 30) {
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
