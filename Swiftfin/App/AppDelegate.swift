//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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

    // TODO: remove after iOS 15 support removed

    private(set) static var instance: AppDelegate! = nil
    var orientationLock: UIInterfaceOrientationMask

    override init() {
        orientationLock = UIDevice.isPad ? .allButUpsideDown : .portrait
    }

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

        AppDelegate.instance = self

        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        orientationLock
    }
}
