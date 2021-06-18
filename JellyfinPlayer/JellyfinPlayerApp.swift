/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI

extension UIDevice {
    var hasNotch: Bool {
        let bottom = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
}

extension View {
    func withHostingWindow(_ callback: @escaping (UIWindow?) -> Void) -> some View {
        self.background(HostingWindowFinder(callback: callback))
    }
}

struct HostingWindowFinder: UIViewRepresentable {
    var callback: (UIWindow?) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async { [weak view] in
            callback(view?.window)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

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
            }
        ))
        box.value = self
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
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
            UIViewController.attemptRotationToDeviceOrientation()
            if _orientations == .landscape {
                let value = UIInterfaceOrientation.landscapeRight.rawValue
                UIDevice.current.setValue(value, forKey: "orientation")
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

@main
struct JellyfinPlayerApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .withHostingWindow { window in
                    window?.rootViewController = PreferenceUIHostingController(wrappedView: SplashView().environment(\.managedObjectContext, persistenceController.container.viewContext))
                }
        }
    }
}
