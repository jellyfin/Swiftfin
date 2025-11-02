//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SliderContainer<Value: BinaryFloatingPoint>: UIViewRepresentable {

    private var value: Binding<Value>
    private let total: Value
    private let onEditingChanged: (Bool) -> Void
    private let view: AnyView

    init(
        value: Binding<Value>,
        total: Value,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder view: @escaping () -> some SliderContentView
    ) {
        self.value = value
        self.total = total
        self.onEditingChanged = onEditingChanged
        self.view = AnyView(view())
    }

    init(
        value: Binding<Value>,
        total: Value,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        view: AnyView
    ) {
        self.value = value
        self.total = total
        self.onEditingChanged = onEditingChanged
        self.view = view
    }

    func makeUIView(context: Context) -> UISliderContainer<Value> {
        UISliderContainer(
            value: value,
            total: total,
            onEditingChanged: onEditingChanged,
            view: view
        )
    }

    func updateUIView(_ uiView: UISliderContainer<Value>, context: Context) {
        DispatchQueue.main.async {
            uiView.containerState.value = value.wrappedValue
        }
    }
}

final class UISliderContainer<Value: BinaryFloatingPoint>: UIControl {

    private let decelerationMaxVelocity: CGFloat = 1000.0
    private let fineTuningVelocityThreshold: CGFloat = 1000.0
    private let panDampingValue: CGFloat = 50

    private let onEditingChanged: (Bool) -> Void
    private let total: Value
    private let valueBinding: Binding<Value>

    private var panGestureRecognizer: DirectionalPanGestureRecognizer!
    private lazy var progressHostingController: UIHostingController<AnyView> = {
        let hostingController = UIHostingController(rootView: AnyView(view.environmentObject(containerState)))
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }()

    private var progressHostingView: UIView { progressHostingController.view }

    let containerState: SliderContainerState<Value>
    let view: AnyView
    private var decelerationTimer: Timer?

    init(
        value: Binding<Value>,
        total: Value,
        onEditingChanged: @escaping (Bool) -> Void,
        view: AnyView
    ) {
        self.onEditingChanged = onEditingChanged
        self.total = total
        self.valueBinding = value
        self.containerState = .init(
            isEditing: false,
            isFocused: false,
            value: value.wrappedValue,
            total: total
        )
        self.view = view
        super.init(frame: .zero)

        setupViews()
        setupGestureRecognizer()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(progressHostingView)
        NSLayoutConstraint.activate([
            progressHostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressHostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressHostingView.topAnchor.constraint(equalTo: topAnchor),
            progressHostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupGestureRecognizer() {
        panGestureRecognizer = DirectionalPanGestureRecognizer(
            direction: .horizontal,
            target: self,
            action: #selector(didPan)
        )
        addGestureRecognizer(panGestureRecognizer)
    }

    private var panDeceleratingVelocity: CGFloat = 0
    private var panStartValue: Value = 0

    @objc
    private func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self).x
        let velocity = gestureRecognizer.velocity(in: self).x

        switch gestureRecognizer.state {
        case .began:
            onEditingChanged(true)
            panStartValue = containerState.value
            stopDeceleratingTimer()
        case .changed:
            let dampedTranslation = translation / panDampingValue
            let newValue = panStartValue + Value(dampedTranslation)
            let clampedValue = clamp(newValue, min: 0, max: containerState.total)

            sendActions(for: .valueChanged)

            containerState.value = clampedValue
            valueBinding.wrappedValue = clampedValue
        case .ended, .cancelled:
            panStartValue = containerState.value

            if abs(velocity) > fineTuningVelocityThreshold {
                let direction: CGFloat = velocity > 0 ? 1 : -1
                panDeceleratingVelocity = (abs(velocity) > decelerationMaxVelocity ? decelerationMaxVelocity * direction : velocity) /
                    panDampingValue
                decelerationTimer = Timer.scheduledTimer(
                    timeInterval: 0.01,
                    target: self,
                    selector: #selector(handleDeceleratingTimer),
                    userInfo: nil,
                    repeats: true
                )
            } else {
                onEditingChanged(false)
                stopDeceleratingTimer()
            }
        default:
            break
        }
    }

    @objc
    private func handleDeceleratingTimer(time: Timer) {
        let newValue = panStartValue + Value(panDeceleratingVelocity) * 0.01
        let clampedValue = clamp(newValue, min: 0, max: containerState.total)

        sendActions(for: .valueChanged)
        panStartValue = clampedValue

        panDeceleratingVelocity *= 0.92

        if !isFocused || abs(panDeceleratingVelocity) < 1 {
            stopDeceleratingTimer()
        }

        valueBinding.wrappedValue = clampedValue
        containerState.value = clampedValue
        onEditingChanged(false)
    }

    private func stopDeceleratingTimer() {
        decelerationTimer?.invalidate()
        decelerationTimer = nil
        panDeceleratingVelocity = 0
        sendActions(for: .valueChanged)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        containerState.isFocused = (context.nextFocusedView == self)
    }
}
