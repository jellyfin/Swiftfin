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

    // MARK: - Background URL Session Handling

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        print("Background URL session events for identifier: \(identifier)")

        // Store the completion handler to be called when background tasks finish
        // This will be handled by the APIClient when it receives background session events
        BackgroundSessionManager.shared.storeCompletionHandler(completionHandler, for: identifier)
    }
}
