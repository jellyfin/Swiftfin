//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

class PreferenceUIHostingController: UIHostingController<AnyView> {

    init<V: View>(@ViewBuilder wrappedView: @escaping () -> V) {
        let box = Box()
        super.init(rootView: AnyView(
            wrappedView()
                .onPreferenceChange(PrefersHomeIndicatorAutoHiddenPreferenceKey.self) {
                    box.value?._prefersHomeIndicatorAutoHidden = $0
                }.onPreferenceChange(SupportedOrientationsPreferenceKey.self) {
                    box.value?._orientations = $0
                }.onPreferenceChange(ViewPreferenceKey.self) {
                    box.value?._viewPreference = $0
                }.onPreferenceChange(KeyCommandsPreferenceKey.self) {
                    box.value?._keyCommands = $0
                }.onPreferenceChange(AddingKeyCommandPreferenceKey.self) {
                    guard let newAction = $0 else { return }
                    box.value?._keyCommands.append(newAction)
                }
        ))
        box.value = self
    }

    @objc
    dynamic required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        super.modalPresentationStyle = .fullScreen
    }

    private class Box {
        weak var value: PreferenceUIHostingController?
        init() {}
    }

    // MARK: Prefers Home Indicator Auto Hidden

    var _prefersHomeIndicatorAutoHidden = false {
        didSet { setNeedsUpdateOfHomeIndicatorAutoHidden() }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        _prefersHomeIndicatorAutoHidden
    }

    // MARK: Lock orientation

    var _orientations: UIInterfaceOrientationMask = .allButUpsideDown {
        didSet {
            print("didset orientations: \(_orientations)")
            if #available(iOS 16.0, *) {
//                setNeedsUpdateOfSupportedInterfaceOrientations()
            } else {
                // Fallback on earlier versions
            }
//            if _orientations == .landscape {
//                let value = UIInterfaceOrientation.landscapeRight.rawValue
//                UIDevice.current.setValue(value, forKey: "orientation")
//                UIViewController.attemptRotationToDeviceOrientation()
//            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        _orientations
    }

    var _viewPreference: UIUserInterfaceStyle = .unspecified {
        didSet {
            overrideUserInterfaceStyle = _viewPreference
        }
    }

    var _keyCommands: [KeyCommandAction] = []

    override var keyCommands: [UIKeyCommand]? {
        let castedCommands: [UIKeyCommand] = _keyCommands.map { .init(
            title: $0.title,
            action: #selector(keyCommandHit),
            input: $0.input,
            modifierFlags: $0.modifierFlags
        ) }

        castedCommands.forEach { $0.wantsPriorityOverSystemBehavior = true }

        return castedCommands
    }

    @objc
    private func keyCommandHit(keyCommand: UIKeyCommand) {
        guard let action = _keyCommands.first(where: { $0.input == keyCommand.input }) else { return }

        action.action()
    }
}

// MARK: Preference Keys

// TODO: look at namespacing?

struct AddingKeyCommandPreferenceKey: PreferenceKey {

    static var defaultValue: KeyCommandAction?

    static func reduce(value: inout KeyCommandAction?, nextValue: () -> KeyCommandAction?) {
        value = nextValue()
    }
}

struct KeyCommandsPreferenceKey: PreferenceKey {

    static var defaultValue: [KeyCommandAction] = []

    static func reduce(value: inout [KeyCommandAction], nextValue: () -> [KeyCommandAction]) {
        value = nextValue()
    }
}

struct PrefersHomeIndicatorAutoHiddenPreferenceKey: PreferenceKey {

    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue() || value
    }
}

struct SupportedOrientationsPreferenceKey: PreferenceKey {

    static var defaultValue: UIInterfaceOrientationMask = .allButUpsideDown

    static func reduce(value: inout UIInterfaceOrientationMask, nextValue: () -> UIInterfaceOrientationMask) {
        // use the most restrictive set from the stack
        value.formIntersection(nextValue())
    }
}

struct ViewPreferenceKey: PreferenceKey {

    static var defaultValue: UIUserInterfaceStyle = .unspecified

    static func reduce(value: inout UIUserInterfaceStyle, nextValue: () -> UIUserInterfaceStyle) {
        value = nextValue()
    }
}

// MARK: Preference Key View Extension

extension View {

    func keyCommands(_ commands: [KeyCommandAction]) -> some View {
        preference(key: KeyCommandsPreferenceKey.self, value: commands)
    }

    func addingKeyCommand(
        title: String,
        input: String,
        modifierFlags: UIKeyModifierFlags = [],
        action: @escaping () -> Void
    ) -> some View {
        preference(
            key: AddingKeyCommandPreferenceKey.self,
            value: .init(title: title, input: input, modifierFlags: modifierFlags, action: action)
        )
    }

    func prefersHomeIndicatorAutoHidden(_ value: Bool) -> some View {
        preference(key: PrefersHomeIndicatorAutoHiddenPreferenceKey.self, value: value)
    }

    func supportedOrientations(_ supportedOrientations: UIInterfaceOrientationMask) -> some View {
        preference(key: SupportedOrientationsPreferenceKey.self, value: supportedOrientations)
    }

    func overrideViewPreference(_ viewPreference: UIUserInterfaceStyle) -> some View {
        preference(key: ViewPreferenceKey.self, value: viewPreference)
    }
}
