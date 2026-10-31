//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Button recognizers for tvOS?
//       - .menu, .select

class UIPreferencesHostingController: UIHostingController<AnyView> {

    init(@ViewBuilder content: () -> some View) {

        #if os(iOS)
        _ = UIViewController.forwardOrientationPreferences
        #endif

        var box = WeakBox<UIPreferencesHostingController>(value: nil)

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
                    input: action.input,
                    modifierFlags: action.modifierFlags
                )

                keyCommand.subtitle = action.subtitle
                keyCommand.wantsPriorityOverSystemBehavior = true

                return keyCommand
            }
        }
    }

    private var _keyCommands: [UIKeyCommand] = []

    override var keyCommands: [UIKeyCommand]? {
        _keyCommands
    }

    @objc
    private func keyCommandHit(keyCommand: UIKeyCommand) {
        guard let action = _keyCommandActions
            .first(where: { $0.input == keyCommand.input && $0.modifierFlags == keyCommand.modifierFlags }) else { return }

        action.action()
    }

    // MARK: Orientation

    private var _orientations: UIInterfaceOrientationMask = .all {
        didSet {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        _orientations
    }

    override var shouldAutorotate: Bool {
        true
    }

    // MARK: Defer Edges

    private var _preferredScreenEdgesDeferringSystemGestures: UIRectEdge = [.left, .right] {
        didSet {
            setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
        }
    }

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        _preferredScreenEdgesDeferringSystemGestures
    }

    // MARK: Home Indicator Auto Hidden

    private var _prefersHomeIndicatorAutoHidden = false {
        didSet {
            setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        _prefersHomeIndicatorAutoHidden
    }
    #endif

    #if os(tvOS)

    override func viewDidLoad() {
        super.viewDidLoad()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(ignorePress))
        gesture.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        view.addGestureRecognizer(gesture)
    }

    @objc
    func ignorePress() {}

    private var _pressCommandActions: [PressCommandAction] = []

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let buttonPress = presses.first?.type, let action = _pressCommandActions
            .first(where: { $0.press == buttonPress }) else { return }

        action.action()
    }
    #endif
}
