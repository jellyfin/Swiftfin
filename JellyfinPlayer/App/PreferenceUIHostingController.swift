//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import UIKit
import SwiftUI

// MARK: PreferenceUIHostingController
class PreferenceUIHostingController: UIHostingController<AnyView> {
    init<V: View>(wrappedView: V) {
        let box = Box()
        super.init(rootView: AnyView(wrappedView
                .onPreferenceChange(PrefersHomeIndicatorAutoHiddenPreferenceKey.self) {
                    box.value?._prefersHomeIndicatorAutoHidden = $0
                }.onPreferenceChange(SupportedOrientationsPreferenceKey.self) {
                    box.value?._orientations = $0
                }.onPreferenceChange(ViewPreferenceKey.self) {
                    box.value?._viewPreference = $0
                }))
        box.value = self
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        super.modalPresentationStyle = .fullScreen
    }

    private class Box {
        weak var value: PreferenceUIHostingController?
        init() {}
    }

    // MARK: Prefers Home Indicator Auto Hidden

    public var _prefersHomeIndicatorAutoHidden = false {
        didSet { setNeedsUpdateOfHomeIndicatorAutoHidden() }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        _prefersHomeIndicatorAutoHidden
    }

    // MARK: Lock orientation

    public var _orientations: UIInterfaceOrientationMask = .allButUpsideDown {
        didSet {
            if _orientations == .landscape {
                let value = UIInterfaceOrientation.landscapeRight.rawValue
                UIDevice.current.setValue(value, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        _orientations
    }

    public var _viewPreference: UIUserInterfaceStyle = .unspecified {
        didSet {
            overrideUserInterfaceStyle = _viewPreference
        }
    }
}

// MARK: Preference Keys
struct PrefersHomeIndicatorAutoHiddenPreferenceKey: PreferenceKey {
    typealias Value = Bool

    static var defaultValue: Value = false

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue() || value
    }
}

struct ViewPreferenceKey: PreferenceKey {
    typealias Value = UIUserInterfaceStyle

    static var defaultValue: UIUserInterfaceStyle = .unspecified

    static func reduce(value: inout UIUserInterfaceStyle, nextValue: () -> UIUserInterfaceStyle) {
        value = nextValue()
    }
}

struct SupportedOrientationsPreferenceKey: PreferenceKey {
    typealias Value = UIInterfaceOrientationMask
    static var defaultValue: UIInterfaceOrientationMask = .allButUpsideDown

    static func reduce(value: inout UIInterfaceOrientationMask, nextValue: () -> UIInterfaceOrientationMask) {
        // use the most restrictive set from the stack
        value.formIntersection(nextValue())
    }
}

// MARK: Preference Key View Extension
extension View {
    // Controls the application's preferred home indicator auto-hiding when this view is shown.
    func prefersHomeIndicatorAutoHidden(_ value: Bool) -> some View {
        preference(key: PrefersHomeIndicatorAutoHiddenPreferenceKey.self, value: value)
    }

    func supportedOrientations(_ supportedOrientations: UIInterfaceOrientationMask) -> some View {
        // When rendered, export the requested orientations upward to Root
        preference(key: SupportedOrientationsPreferenceKey.self, value: supportedOrientations)
    }

    func overrideViewPreference(_ viewPreference: UIUserInterfaceStyle) -> some View {
        // When rendered, export the requested orientations upward to Root
        preference(key: ViewPreferenceKey.self, value: viewPreference)
    }
}
