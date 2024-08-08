//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: remove after iOS 15 support removed

enum AppRotationUtility {

    static func lockOrientation(_ orientationLock: UIInterfaceOrientationMask) {

        guard UIDevice.isPhone else { return }

        AppDelegate.instance.orientationLock = orientationLock

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

struct iOS15LandscapeView<Content: View>: UIViewControllerRepresentable {

    let content: () -> Content

    func makeUIViewController(context: Context) -> UIiOS15LandscapeView<Content> {
        UIiOS15LandscapeView<Content>(rootView: content())
    }

    func updateUIViewController(_ uiViewController: UIiOS15LandscapeView<Content>, context: Context) {}
}

class UIiOS15LandscapeView<Content: View>: UIHostingController<Content> {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        AppRotationUtility.lockOrientation(.landscape)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        AppRotationUtility.lockOrientation(.portrait)
    }
}
