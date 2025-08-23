//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

// Modification of https://github.com/zattoo/TvOSSlider

import SwiftUI
import UIKit

// TODO: Replace

private let trackViewHeight: CGFloat = 5
private let animationDuration: TimeInterval = 0.3
private let defaultValue: Float = 0
private let defaultMinimumValue: Float = 0
private let defaultMaximumValue: Float = 1
private let defaultIsContinuous: Bool = true
private let defaultThumbTintColor: UIColor = .white
private let defaultTrackColor: UIColor = .gray
private let defaultMininumTrackTintColor: UIColor = .blue
private let defaultFocusScaleFactor: CGFloat = 1.05
private let defaultStepValue: Float = 0.1
private let decelerationRate: Float = 0.92
private let decelerationMaxVelocity: Float = 1000

/// A control used to select a single value from a continuous range of values.
final class UITVOSSlider: UIControl {

    /// The slider’s current value.
    var value: Float {
        get {
            storedValue
        }
        set {
            storedValue = min(maximumValue, newValue)
            storedValue = max(minimumValue, storedValue)

            var offset = trackView.bounds.width * CGFloat((storedValue - minimumValue) / (maximumValue - minimumValue))
            offset = min(trackView.bounds.width, offset)
            thumbViewCenterXConstraint.constant = offset
        }
    }

    /// The minimum value of the slider.
    var minimumValue: Float = defaultMinimumValue {
        didSet {
            value = max(value, minimumValue)
        }
    }

    /// The maximum value of the slider.
    var maximumValue: Float = defaultMaximumValue {
        didSet {
            value = min(value, maximumValue)
        }
    }

    /// A Boolean value indicating whether changes in the slider’s value generate continuous update events.
    var isContinuous: Bool = defaultIsContinuous

    /// The color used to tint the default minimum track images.
    var minimumTrackTintColor: UIColor? = defaultMininumTrackTintColor {
        didSet {
            minimumTrackView.backgroundColor = minimumTrackTintColor
        }
    }

    /// The color used to tint the default maximum track images.
    var maximumTrackTintColor: UIColor? {
        didSet {
            maximumTrackView.backgroundColor = maximumTrackTintColor
        }
    }

    /// The color used to tint the default thumb images.
    var thumbTintColor: UIColor = defaultThumbTintColor {
        didSet {
            thumbView.backgroundColor = thumbTintColor
        }
    }

    /// Scale factor applied to the slider when receiving the focus
    var focusScaleFactor: CGFloat = defaultFocusScaleFactor {
        didSet {
            updateStateDependantViews()
        }
    }

    /// Value added or subtracted from the current value on steps left or right updates
    var stepValue: Float = defaultStepValue

    /// Damping value for panning gestures
    var panDampingValue: Float = 5

    // Size for thumb view
    var thumbSize: CGFloat = 30

    var fineTunningVelocityThreshold: Float = 600

    /**
     Sets the slider’s current value, allowing you to animate the change visually.

     - Parameters:
        - value: The new value to assign to the value property
        - animated: Specify true to animate the change in value; otherwise, specify false to update the slider’s appearance immediately. Animations are performed asynchronously and do not block the calling thread.
     */
    func setValue(_ value: Float, animated: Bool) {
        self.value = value
        stopDeceleratingTimer()

        if animated {
            UIView.animate(withDuration: animationDuration) {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }
    }

    /**
     Assigns a minimum track image to the specified control states.

     - Parameters:
        - image: The minimum track image to associate with the specified states.
        - state: The control state with which to associate the image.
     */
    func setMinimumTrackImage(_ image: UIImage?, for state: UIControl.State) {
        minimumTrackViewImages[state.rawValue] = image
        updateStateDependantViews()
    }

    /**
     Assigns a maximum track image to the specified control states.

     - Parameters:
        - image: The maximum track image to associate with the specified states.
        - state: The control state with which to associate the image.
     */
    func setMaximumTrackImage(_ image: UIImage?, for state: UIControl.State) {
        maximumTrackViewImages[state.rawValue] = image
        updateStateDependantViews()
    }

    /**
     Assigns a thumb image to the specified control states.

     - Parameters:
        - image: The thumb image to associate with the specified states.
        - state: The control state with which to associate the image.
     */
    func setThumbImage(_ image: UIImage?, for state: UIControl.State) {
        thumbViewImages[state.rawValue] = image
        updateStateDependantViews()
    }

    // MARK: - Initializers

    private var onEditingChanged: (Bool) -> Void
    private var valueBinding: Binding<CGFloat>

    init(
        value: Binding<CGFloat>,
        onEditingChanged: @escaping (Bool) -> Void
    ) {
        self.onEditingChanged = onEditingChanged
        self.valueBinding = value

        super.init(frame: .zero)

        setUpView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UIControlStates

    /// :nodoc:
    override var isEnabled: Bool {
        didSet {
            panGestureRecognizer.isEnabled = isEnabled
            updateStateDependantViews()
        }
    }

    /// :nodoc:
    override var isSelected: Bool {
        didSet {
            updateStateDependantViews()
        }
    }

    /// :nodoc:
    override var isHighlighted: Bool {
        didSet {
            updateStateDependantViews()
        }
    }

    /// :nodoc:
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.updateStateDependantViews()
        }, completion: nil)
    }

    // MARK: - Private

    private typealias ControlState = UInt

    private var storedValue: Float = defaultValue

    private var thumbViewImages: [ControlState: UIImage] = [:]
    private var thumbView: UIImageView!

    private var trackViewImages: [ControlState: UIImage] = [:]
    private var trackView: UIImageView!

    private var minimumTrackViewImages: [ControlState: UIImage] = [:]
    private var minimumTrackView: UIImageView!

    private var maximumTrackViewImages: [ControlState: UIImage] = [:]
    private var maximumTrackView: UIImageView!

    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var leftTapGestureRecognizer: UITapGestureRecognizer!
    private var rightTapGestureRecognizer: UITapGestureRecognizer!

    private var thumbViewCenterXConstraint: NSLayoutConstraint!

    private weak var deceleratingTimer: Timer?
    private var deceleratingVelocity: Float = 0

    private var thumbViewCenterXConstraintConstant: Float = 0

    private func setUpView() {
        setUpTrackView()
        setUpMinimumTrackView()
        setUpMaximumTrackView()
        setUpThumbView()

        setUpTrackViewConstraints()
        setUpMinimumTrackViewConstraints()
        setUpMaximumTrackViewConstraints()
        setUpThumbViewConstraints()

        setUpGestures()

        updateStateDependantViews()
    }

    private func setUpThumbView() {
        thumbView = UIImageView()
        thumbView.layer.cornerRadius = thumbSize / 6
        thumbView.backgroundColor = thumbTintColor
        addSubview(thumbView)
    }

    private func setUpTrackView() {
        trackView = UIImageView()
        trackView.layer.cornerRadius = trackViewHeight / 2
        trackView.backgroundColor = defaultTrackColor.withAlphaComponent(0.3)
        addSubview(trackView)
    }

    private func setUpMinimumTrackView() {
        minimumTrackView = UIImageView()
        minimumTrackView.layer.cornerRadius = trackViewHeight / 2
        minimumTrackView.backgroundColor = minimumTrackTintColor
        addSubview(minimumTrackView)
    }

    private func setUpMaximumTrackView() {
        maximumTrackView = UIImageView()
        maximumTrackView.layer.cornerRadius = trackViewHeight / 2
        maximumTrackView.backgroundColor = maximumTrackTintColor
        addSubview(maximumTrackView)
    }

    private func setUpTrackViewConstraints() {
        trackView.translatesAutoresizingMaskIntoConstraints = false
        trackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        trackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        trackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        trackView.heightAnchor.constraint(equalToConstant: trackViewHeight).isActive = true
    }

    private func setUpMinimumTrackViewConstraints() {
        minimumTrackView.translatesAutoresizingMaskIntoConstraints = false
        minimumTrackView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor).isActive = true
        minimumTrackView.trailingAnchor.constraint(equalTo: thumbView.centerXAnchor).isActive = true
        minimumTrackView.centerYAnchor.constraint(equalTo: trackView.centerYAnchor).isActive = true
        minimumTrackView.heightAnchor.constraint(equalToConstant: trackViewHeight).isActive = true
    }

    private func setUpMaximumTrackViewConstraints() {
        maximumTrackView.translatesAutoresizingMaskIntoConstraints = false
        maximumTrackView.leadingAnchor.constraint(equalTo: thumbView.centerXAnchor).isActive = true
        maximumTrackView.trailingAnchor.constraint(equalTo: trackView.trailingAnchor).isActive = true
        maximumTrackView.centerYAnchor.constraint(equalTo: trackView.centerYAnchor).isActive = true
        maximumTrackView.heightAnchor.constraint(equalToConstant: trackViewHeight).isActive = true
    }

    private func setUpThumbViewConstraints() {
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        thumbView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        thumbView.widthAnchor.constraint(equalToConstant: thumbSize / 3).isActive = true
        thumbView.heightAnchor.constraint(equalToConstant: thumbSize).isActive = true
        thumbViewCenterXConstraint = thumbView.centerXAnchor.constraint(equalTo: trackView.leadingAnchor, constant: CGFloat(value))
        thumbViewCenterXConstraint.isActive = true
    }

    private func setUpGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureWasTriggered(panGestureRecognizer:)))
        addGestureRecognizer(panGestureRecognizer)

        leftTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(leftTapWasTriggered))
        leftTapGestureRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.leftArrow.rawValue)]
        leftTapGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        addGestureRecognizer(leftTapGestureRecognizer)

        rightTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(rightTapWasTriggered))
        rightTapGestureRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.rightArrow.rawValue)]
        rightTapGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        addGestureRecognizer(rightTapGestureRecognizer)
    }

    private func updateStateDependantViews() {
        thumbView.image = thumbViewImages[state.rawValue] ?? thumbViewImages[UIControl.State.normal.rawValue]

        if isFocused {
            thumbView.transform = CGAffineTransform(scaleX: focusScaleFactor, y: focusScaleFactor)
        } else {
            thumbView.transform = CGAffineTransform.identity
        }
    }

    @objc
    private func handleDeceleratingTimer(timer: Timer) {
        let centerX = thumbViewCenterXConstraintConstant + deceleratingVelocity * 0.01
        let percent = centerX / Float(trackView.frame.width)
        value = minimumValue + ((maximumValue - minimumValue) * percent)

        if isContinuous {
            sendActions(for: .valueChanged)
        }

        thumbViewCenterXConstraintConstant = Float(thumbViewCenterXConstraint.constant)

        deceleratingVelocity *= decelerationRate
        if !isFocused || abs(deceleratingVelocity) < 1 {
            stopDeceleratingTimer()
        }

        valueBinding.wrappedValue = CGFloat(percent)
        onEditingChanged(false)
    }

    private func stopDeceleratingTimer() {
        deceleratingTimer?.invalidate()
        deceleratingTimer = nil
        deceleratingVelocity = 0
        sendActions(for: .valueChanged)
    }

    private func isVerticalGesture(_ recognizer: UIPanGestureRecognizer) -> Bool {
        let translation = recognizer.translation(in: self)
        if abs(translation.y) > abs(translation.x) {
            return true
        }
        return false
    }

    // MARK: - Actions

    @objc
    private func panGestureWasTriggered(panGestureRecognizer: UIPanGestureRecognizer) {

        guard !isVerticalGesture(panGestureRecognizer) else { return }

        let translation = Float(panGestureRecognizer.translation(in: self).x)
        let velocity = Float(panGestureRecognizer.velocity(in: self).x)

        switch panGestureRecognizer.state {
        case .began:
            onEditingChanged(true)

            stopDeceleratingTimer()
            thumbViewCenterXConstraintConstant = Float(thumbViewCenterXConstraint.constant)
        case .changed:
            let centerX = thumbViewCenterXConstraintConstant + translation / panDampingValue
            let percent = centerX / Float(trackView.frame.width)
            value = minimumValue + ((maximumValue - minimumValue) * percent)
            if isContinuous {
                sendActions(for: .valueChanged)
            }

            valueBinding.wrappedValue = CGFloat(percent)
        case .ended, .cancelled:

            thumbViewCenterXConstraintConstant = Float(thumbViewCenterXConstraint.constant)

            if abs(velocity) > fineTunningVelocityThreshold {
                let direction: Float = velocity > 0 ? 1 : -1
                deceleratingVelocity = abs(velocity) > decelerationMaxVelocity ? decelerationMaxVelocity * direction : velocity
                deceleratingTimer = Timer.scheduledTimer(
                    timeInterval: 0.01,
                    target: self,
                    selector: #selector(handleDeceleratingTimer(timer:)),
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
    private func leftTapWasTriggered() {
        //        setValue(value-stepValue, animated: true)
//        viewModel.playerOverlayDelegate?.didSelectBackward()
    }

    @objc
    private func rightTapWasTriggered() {
        //        setValue(value+stepValue, animated: true)
//        viewModel.playerOverlayDelegate?.didSelectForward()
    }
}
