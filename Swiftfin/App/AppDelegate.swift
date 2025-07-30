//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import AVFAudio
import CoreStore
import Defaults
import Logging
import PreferencesView
import Pulse
import PulseLogHandler
import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

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
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let keyWindow = scene.keyWindow,
           let topViewCOntroller = keyWindow.rootViewController
        {
            if let preferencesHostingController = topViewCOntroller.presentedViewController as? UIPreferencesHostingController {
                return preferencesHostingController.supportedInterfaceOrientations
            }
        }

        return UIDevice.isPad ? .allButUpsideDown : .portrait
    }
}
