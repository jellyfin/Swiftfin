//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: make a `StyledView`

struct SliderContainer<Value: BinaryFloatingPoint, Content: SliderContentView>: UIViewRepresentable {

    private var value: Binding<Value>
    private let total: Value
    private let isScrollingEnabled: Bool
    private let originProgress: Value?
    private let onEditingChanged: (Bool) -> Void
    private let view: Content

    init(
        value: Binding<Value>,
        total: Value,
        isScrollingEnabled: Bool = true,
        originProgress: Value? = nil,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder view: @escaping () -> Content
    ) {
        self.value = value
        self.total = total
        self.isScrollingEnabled = isScrollingEnabled
        self.originProgress = originProgress
        self.onEditingChanged = onEditingChanged
        self.view = view()
    }

    func makeUIView(context: Context) -> UISliderContainer<Value, Content> {
        UISliderContainer(
            value: value,
            total: total,
            isScrollingEnabled: isScrollingEnabled,
            originProgress: originProgress,
            onEditingChanged: onEditingChanged,
            view: view
        )
    }

    func updateUIView(_ uiView: UISliderContainer<Value, Content>, context: Context) {
        uiView.update(
            value: value.wrappedValue,
            isScrollingEnabled: isScrollingEnabled,
            originProgress: originProgress,
            view: view
        )
    }
}

final class UISliderContainer<Value: BinaryFloatingPoint, Content: SliderContentView>: UIControl {

    private let decelerationMaxVelocity: CGFloat = 1000.0
    private let fineTuningVelocityThreshold: CGFloat = 1000.0
    private let panDampingValue: CGFloat = 200

    private let onEditingChanged: (Bool) -> Void
    private let total: Value
    private let valueBinding: Binding<Value>
    private var isScrollingEnabled: Bool

    private var panGestureRecognizer: DirectionalPanGestureRecognizer!
    private lazy var progressHostingController: UIHostingController<AnyView> = {
        let hostingController = UIHostingController(rootView: AnyView(view.environmentObject(containerState)))
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }()

    private var progressHostingView: UIView {
        progressHostingController.view
    }

    let containerState: SliderContainerState<Value>
    private var view: Content
    private var decelerationTimer: Timer?

    override var canBecomeFocused: Bool {
        isEnabled && !isHidden && alpha > 0
    }

    init(
        value: Binding<Value>,
        total: Value,
        isScrollingEnabled: Bool,
        originProgress: Value?,
        onEditingChanged: @escaping (Bool) -> Void,
        view: Content
    ) {
        self.onEditingChanged = onEditingChanged
        self.total = total
        self.valueBinding = value
        self.isScrollingEnabled = isScrollingEnabled
        self.containerState = .init(
            isEditing: false,
            isFocused: false,
            isScrollingEnabled: isScrollingEnabled,
            value: value.wrappedValue,
            originValue: originProgress,
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

    func update(
        value: Value,
        isScrollingEnabled: Bool,
        originProgress: Value?,
        view: Content
    ) {
        progressHostingController.rootView = AnyView(view.environmentObject(containerState))
        setScrollingEnabled(isScrollingEnabled, publishState: false)

        // Skip updates if the value is unchanged.
        guard containerState.value != value || containerState.originValue != originProgress || containerState
            .isScrollingEnabled != isScrollingEnabled else { return }

        // `updateUIView` is part of SwiftUI's view update pass, so writes to @Published properties here produce warnings.
        Task { @MainActor [weak self, weak containerState] in
            self?.setScrollingEnabled(isScrollingEnabled)
            guard let containerState else { return }
            if containerState.value != value {
                containerState.value = value
            }
            if containerState.originValue != originProgress {
                containerState.originValue = originProgress
            }
            if containerState.isScrollingEnabled != isScrollingEnabled {
                containerState.isScrollingEnabled = isScrollingEnabled
            }
        }
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
        panGestureRecognizer.isEnabled = isScrollingEnabled
        addGestureRecognizer(panGestureRecognizer)
    }

    private var panDeceleratingVelocity: CGFloat = 0
    private var panStartValue: Value = 0

    @objc
    private func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard isScrollingEnabled else {
            return
        }

        let translation = gestureRecognizer.translation(in: self).x
        let velocity = gestureRecognizer.velocity(in: self).x

        switch gestureRecognizer.state {
        case .began:
            setEditing(true)
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
                    timeInterval: 0.03,
                    target: self,
                    selector: #selector(handleDeceleratingTimer),
                    userInfo: nil,
                    repeats: true
                )
            } else {
                setEditing(false)
                stopDeceleratingTimer()
            }
        default:
            break
        }
    }

    @objc
    private func handleDeceleratingTimer(time: Timer) {
        guard isScrollingEnabled else {
            stopDeceleratingTimer()
            setEditing(false)
            return
        }

        let newValue = panStartValue + Value(panDeceleratingVelocity) * 0.03
        let clampedValue = clamp(newValue, min: 0, max: containerState.total)

        sendActions(for: .valueChanged)
        panStartValue = clampedValue

        panDeceleratingVelocity *= 0.78

        if !containerState.isFocused || abs(panDeceleratingVelocity) < 1 {
            stopDeceleratingTimer()
            setEditing(false)
            return
        }

        valueBinding.wrappedValue = clampedValue
        containerState.value = clampedValue
    }

    private func setScrollingEnabled(_ isScrollingEnabled: Bool, publishState: Bool = true) {
        guard self.isScrollingEnabled != isScrollingEnabled || (publishState && containerState.isScrollingEnabled != isScrollingEnabled)
        else {
            return
        }

        self.isScrollingEnabled = isScrollingEnabled
        panGestureRecognizer?.isEnabled = isScrollingEnabled

        if publishState && containerState.isScrollingEnabled != isScrollingEnabled {
            containerState.isScrollingEnabled = isScrollingEnabled
        }

        if !isScrollingEnabled {
            stopDeceleratingTimer()
            setEditing(false, publishState: publishState)
        }
    }

    private func setEditing(_ isEditing: Bool, publishState: Bool = true) {
        guard containerState.isEditing != isEditing else {
            return
        }

        guard publishState else {
            return
        }

        onEditingChanged(isEditing)
        containerState.isEditing = isEditing
    }

    private func stopDeceleratingTimer() {
        decelerationTimer?.invalidate()
        decelerationTimer = nil
        panDeceleratingVelocity = 0
        sendActions(for: .valueChanged)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        containerState.isFocused = containsFocusedItem(context.nextFocusedView)
    }

    private func containsFocusedItem(_ focusedView: UIView?) -> Bool {
        guard let focusedView else {
            return false
        }

        return focusedView === self || focusedView.isDescendant(of: self)
    }
}
