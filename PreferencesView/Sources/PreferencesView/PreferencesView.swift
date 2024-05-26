//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import SwizzleSwift

public struct PreferencesView<Content: View>: UIViewControllerRepresentable {

    private var content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        _ = UIViewController.swizzlePreferences
        self.content = content
    }

    public func makeUIViewController(context: Context) -> UIPreferencesHostingController {
        let controller = UIPreferencesHostingController(content: content)
        self.addGesture(press: .menu, view: controller.view, coordinator: context.coordinator)
        return controller
    }

    func addGesture(press: UIPress.PressType, view: UIView, coordinator: Coordinator) {
        let gesture = UITapGestureRecognizer(target: coordinator, action: #selector(coordinator.ignorePress))
        gesture.allowedPressTypes = [NSNumber(value: press.rawValue)]
        view.addGestureRecognizer(gesture)
    }

    public func updateUIViewController(_ uiViewController: UIPreferencesHostingController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public class Coordinator: NSObject {
        @objc
        func ignorePress() {}
    }
}
