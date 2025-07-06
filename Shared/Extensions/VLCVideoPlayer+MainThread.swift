//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI
import VLCUI
import AVFoundation

extension VLCVideoPlayer.Proxy {
    
    /// Thread-safe wrapper for VLC proxy operations to ensure UI updates happen on main thread
    @MainActor
    class MainThreadProxy {
        private let proxy: VLCVideoPlayer.Proxy
        
        init(proxy: VLCVideoPlayer.Proxy) {
            self.proxy = proxy
        }
        
        func play() {
            Task { @MainActor in
                proxy.play()
            }
        }
        
        func pause() {
            Task { @MainActor in
                proxy.pause()
            }
        }
        
        func stop() {
            Task { @MainActor in
                proxy.stop()
            }
        }
        
        func setTime(_ time: VLCVideoPlayer.Time) {
            Task { @MainActor in
                proxy.setTime(time)
            }
        }
        
        func setRate(_ rate: VLCVideoPlayer.Rate) {
            Task { @MainActor in
                proxy.setRate(rate)
            }
        }
        
        func setAudioDelay(_ delay: VLCVideoPlayer.Time) {
            Task { @MainActor in
                proxy.setAudioDelay(delay)
            }
        }
        
        func setSubtitleDelay(_ delay: VLCVideoPlayer.Time) {
            Task { @MainActor in
                proxy.setSubtitleDelay(delay)
            }
        }
        
        func setSubtitleColor(_ color: VLCVideoPlayer.SubtitleColor) {
            Task { @MainActor in
                proxy.setSubtitleColor(color)
            }
        }
        
        func setSubtitleSize(_ size: VLCVideoPlayer.SubtitleSize) {
            Task { @MainActor in
                proxy.setSubtitleSize(size)
            }
        }
        
        func setSubtitleFont(_ fontName: String) {
            Task { @MainActor in
                proxy.setSubtitleFont(fontName)
            }
        }
        
        func aspectFill(_ fill: CGFloat) {
            Task { @MainActor in
                UIView.animate(withDuration: 0.2) {
                    proxy.aspectFill(fill)
                }
            }
        }
        
        func playNewMedia(_ configuration: VLCVideoPlayer.Configuration) {
            Task { @MainActor in
                proxy.playNewMedia(configuration)
            }
        }
        
        func jumpForward(_ seconds: Int) {
            Task { @MainActor in
                proxy.jumpForward(seconds)
            }
        }
        
        func jumpBackward(_ seconds: Int) {
            Task { @MainActor in
                proxy.jumpBackward(seconds)
            }
        }
    }
}

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