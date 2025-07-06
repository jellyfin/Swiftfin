//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import VLCUI

// MARK: - Audio Session Configuration

extension VLCVideoPlayer {

    /// Configure audio session for optimal playback and prevent audio overload
    static func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()

            // Set category for video playback with audio
            try audioSession.setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.mixWithOthers, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )

            // Configure for optimal performance
            try audioSession.setPreferredSampleRate(48000) // Standard video sample rate
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms buffer

            // Activate the session
            try audioSession.setActive(true)

        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    /// Reset audio session when stopping playback
    static func resetAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}
