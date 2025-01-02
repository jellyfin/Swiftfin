//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

public class UIPreferencesHostingController: UIHostingController<AnyView> {

    init<Content: View>(@ViewBuilder content: @escaping () -> Content) {
        let box = Box()
        let rootView = AnyView(
            content()
            #if os(iOS)
                .onPreferenceChange(KeyCommandsPreferenceKey.self) {
                    box.value?._keyCommandActions = $0
                }
                .onPreferenceChange(PrefersHomeIndicatorAutoHiddenPreferenceKey.self) {
                    box.value?._prefersHomeIndicatorAutoHidden = $0
                }
                .onPreferenceChange(PreferredScreenEdgesDeferringSystemGesturesPreferenceKey.self) {
                    box.value?._preferredScreenEdgesDeferringSystemGestures = $0
                }
                .onPreferenceChange(SupportedOrientationsPreferenceKey.self) {
                    box.value?._orientations = $0
                }
            #elseif os(tvOS)
                .onPreferenceChange(PressCommandsPreferenceKey.self) {
                    box.value?._pressCommandActions = $0
                }
            #endif
        )

        super.init(rootView: rootView)

        box.value = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if os(iOS)

    // MARK: Key Commands

    private var _keyCommandActions: [KeyCommandAction] = [] {
        willSet {
            _keyCommands = newValue.map { action in
                let keyCommand = UIKeyCommand(
                    title: action.title,
                    action: #selector(keyCommandHit),
                    input: String(action.input),
                    modifierFlags: action.modifierFlags
                )

                keyCommand.subtitle = action.subtitle
                keyCommand.wantsPriorityOverSystemBehavior = true

                return keyCommand
            }
        }
    }

    private var _keyCommands: [UIKeyCommand] = []

    override public var keyCommands: [UIKeyCommand]? {
        _keyCommands
    }

    @objc
    private func keyCommandHit(keyCommand: UIKeyCommand) {
        guard let action = _keyCommandActions
            .first(where: { $0.input == keyCommand.input && $0.modifierFlags == keyCommand.modifierFlags }) else { return }
        action.action()
    }

    // MARK: Orientation

    var _orientations: UIInterfaceOrientationMask = .all {
        didSet {
            if #available(iOS 16, *) {
                setNeedsUpdateOfSupportedInterfaceOrientations()
            } else {
                AppRotationUtility.lockOrientation(_orientations)
            }
        }
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        _orientations
    }

    // MARK: Defer Edges

    private var _preferredScreenEdgesDeferringSystemGestures: UIRectEdge = [.left, .right] {
        didSet { setNeedsUpdateOfScreenEdgesDeferringSystemGestures() }
    }

    override public var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        _preferredScreenEdgesDeferringSystemGestures
    }

    // MARK: Home Indicator Auto Hidden

    private var _prefersHomeIndicatorAutoHidden = false {
        didSet { setNeedsUpdateOfHomeIndicatorAutoHidden() }
    }

    override public var prefersHomeIndicatorAutoHidden: Bool {
        _prefersHomeIndicatorAutoHidden
    }

    #endif

    #if os(tvOS)

    override public func viewDidLoad() {
        super.viewDidLoad()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(ignorePress))
        gesture.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        view.addGestureRecognizer(gesture)
    }

    @objc
    func ignorePress() {}

    private var _pressCommandActions: [PressCommandAction] = []

    override public func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let buttonPress = presses.first?.type else { return }

        guard let action = _pressCommandActions
            .first(where: { $0.press == buttonPress }) else { return }
        action.action()
    }
    #endif
}

// TODO: remove after iOS 15 support removed

#if os(iOS)
enum AppRotationUtility {

    static func lockOrientation(_ orientationLock: UIInterfaceOrientationMask) {

        guard UIDevice.current.userInterfaceIdiom == .phone else { return }

        let rotateOrientation: UIInterfaceOrientation

        switch orientationLock {
        case .landscape:
            rotateOrientation = .landscapeRight
        default:
            rotateOrientation = .portrait
        }

        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }
}
#endif
