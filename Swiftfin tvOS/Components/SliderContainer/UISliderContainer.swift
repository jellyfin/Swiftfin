//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

final class UISliderContainer<Value: BinaryFloatingPoint>: UIControl {

    private let decelerationMaxVelocity: CGFloat = 1000.0
    private let fineTuningVelocityThreshold: CGFloat = 1000.0
    private let panDampingValue: CGFloat = 200

    private var onEditingChanged: (Bool) -> Void
    private var value: Binding<Value>
    private var total: Value
    private var isScrollingEnabled: Bool
    private var onFocusChanged: (Bool) -> Void

    private var panGestureRecognizer: DirectionalPanGestureRecognizer!
    private var decelerationTimer: Timer?
    private var panDeceleratingVelocity: CGFloat = 0
    private var panStartValue: Value = 0

    override var canBecomeFocused: Bool {
        isEnabled && !isHidden && alpha > 0
    }

    init(
        value: Binding<Value>,
        total: Value,
        isScrollingEnabled: Bool,
        onEditingChanged: @escaping (Bool) -> Void,
        onFocusChanged: @escaping (Bool) -> Void
    ) {
        self.value = value
        self.total = total
        self.isScrollingEnabled = isScrollingEnabled
        self.onEditingChanged = onEditingChanged
        self.onFocusChanged = onFocusChanged
        super.init(frame: .zero)

        panGestureRecognizer = DirectionalPanGestureRecognizer(
            direction: .horizontal,
            target: self,
            action: #selector(didPan)
        )
        panGestureRecognizer.isEnabled = isScrollingEnabled
        addGestureRecognizer(panGestureRecognizer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(
        value: Binding<Value>,
        total: Value,
        isScrollingEnabled: Bool,
        onEditingChanged: @escaping (Bool) -> Void,
        onFocusChanged: @escaping (Bool) -> Void
    ) {
        self.value = value
        self.total = total
        self.onEditingChanged = onEditingChanged
        self.onFocusChanged = onFocusChanged

        guard self.isScrollingEnabled != isScrollingEnabled else { return }
        self.isScrollingEnabled = isScrollingEnabled
        panGestureRecognizer.isEnabled = isScrollingEnabled

        if !isScrollingEnabled {
            stopDecelerating()
        }
    }

    @objc
    private func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard isScrollingEnabled else { return }

        switch gestureRecognizer.state {
        case .began:
            stopDecelerating()
            onEditingChanged(true)
            panStartValue = value.wrappedValue
        case .changed:
            let translation = gestureRecognizer.translation(in: self).x / panDampingValue
            setValue(panStartValue + Value(translation))
        case .ended:
            panStartValue = value.wrappedValue
            let velocity = gestureRecognizer.velocity(in: self).x

            if abs(velocity) > fineTuningVelocityThreshold {
                panDeceleratingVelocity = clamp(velocity, min: -decelerationMaxVelocity, max: decelerationMaxVelocity) / panDampingValue
                decelerationTimer = Timer.scheduledTimer(
                    timeInterval: 0.03,
                    target: self,
                    selector: #selector(handleDeceleratingTimer),
                    userInfo: nil,
                    repeats: true
                )
            } else {
                onEditingChanged(false)
            }
        case .cancelled, .failed:
            stopDecelerating()
            onEditingChanged(false)
        default:
            break
        }
    }

    @objc
    private func handleDeceleratingTimer(time: Timer) {
        guard isScrollingEnabled, isFocused, abs(panDeceleratingVelocity) >= 1 else {
            stopDecelerating()
            onEditingChanged(false)
            return
        }

        setValue(panStartValue + Value(panDeceleratingVelocity) * 0.03)
        panStartValue = value.wrappedValue
        panDeceleratingVelocity *= 0.78
    }

    private func setValue(_ newValue: Value) {
        let clampedValue = clamp(newValue, min: 0, max: total)
        guard value.wrappedValue != clampedValue else { return }
        value.wrappedValue = clampedValue
        sendActions(for: .valueChanged)
    }

    func stopDecelerating() {
        decelerationTimer?.invalidate()
        decelerationTimer = nil
        panDeceleratingVelocity = 0
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        onFocusChanged(isFocused)
        if !isFocused {
            stopDecelerating()
            onEditingChanged(false)
        }
    }
}
