//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import AVFAudio
import CoreStore
import Defaults
import Logging
import Pulse
import PulseLogHandler
import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    static var orientationLock: UIInterfaceOrientationMask = .all

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback)
        } catch {
            print("setting category AVAudioSessionCategoryPlayback failed")
        }

        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }

    static func enterPlaybackOrientation() {
        AppDelegate.changeOrientation(.landscape)
    }

    static func leavePlaybackOrientation() {
        if UIDevice.isIPad {
            AppDelegate.changeOrientation(.allButUpsideDown)
        } else {
            // On iPhone, users likely want to return to portrait mode after leaving playback.
            // However, we don't want to lock them into portrait mode, so switch back after a delay.
            AppDelegate.changeOrientation(.portrait)

            // 0.25 seconds is about the time to switch from landscape to portrait.
            // Changing orientation again too early will cause the top time/battery bar to remain
            // at the side instead of moving up top, like it should.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                AppDelegate.changeOrientation(.allButUpsideDown)
            }
        }
    }

    private static func changeOrientation(_ orientation: UIInterfaceOrientationMask) {
        guard UIDevice.isPhone || UIDevice.isIPad else { return }

        orientationLock = orientation

        if #available(iOS 16, *) {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }
    }
}
