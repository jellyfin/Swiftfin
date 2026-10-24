//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import Defaults
import Foundation
@preconcurrency import GoogleCast
import Observation

@MainActor
@Observable
final class ChromecastController: NSObject, @preconcurrency GCKSessionManagerListener, @preconcurrency GCKDiscoveryManagerListener {

    private static var instance: ChromecastController?

    // TODO: use Factory
    static var shared: ChromecastController {
        if let instance {
            return instance
        }
        
        let controller = ChromecastController()
        instance = controller
        return controller
    }

    private(set) var devices: [GCKDevice] = []
    @ObservationIgnored
    private weak var mediaSession: MediaSession?

    override private init() {
        super.init()
        
        let criteria = GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID)
        let options = GCKCastOptions(discoveryCriteria: criteria)
        options.disableDiscoveryAutostart = true
        options.startDiscoveryAfterFirstTapOnCastButton = false
        options.suspendSessionsWhenBackgrounded = true
        options.stopReceiverApplicationWhenEndingSession = true
        GCKCastContext.setSharedInstanceWith(options)
        
        let context = GCKCastContext.sharedInstance()
        
        context.sessionManager.add(self)
        context.discoveryManager.add(self)
    }

    func startDiscovery() {
        guard Defaults[.Experimental.chromecast] else { return }

        GCKCastContext.sharedInstance().discoveryManager.startDiscovery()
        didUpdateDeviceList()
    }

    func stopDiscovery() {
        GCKCastContext.sharedInstance().discoveryManager.stopDiscovery()
    }

    static func updateAvailability() {
        guard !Defaults[.Experimental.chromecast], let instance else { return }

        let context = GCKCastContext.sharedInstance()
        context.discoveryManager.stopDiscovery()
        instance.devices = []
        
        let mediaSession = instance.mediaSession
        instance.mediaSession = nil
        
        Task {
            await mediaSession?.returnToLocalPlayback()?.value
            guard !Defaults[.Experimental.chromecast] else { return }

            context.sessionManager.endSessionAndStopCasting(true)
        }
    }

    func didUpdateDeviceList() {
        guard Defaults[.Experimental.chromecast] else { return }

        let discovery = GCKCastContext.sharedInstance().discoveryManager
        devices = (0 ..< discovery.deviceCount).map { discovery.device(at: $0) }
    }

    func select(_ device: GCKDevice, for mediaSession: MediaSession) {
        guard Defaults[.Experimental.chromecast], mediaSession.canControlPlayback,
              mediaSession.item.mediaType == .video else { return }

        self.mediaSession = mediaSession
        
        Task {
            let sessions = GCKCastContext.sharedInstance().sessionManager
            
            if let current = sessions.currentCastSession, current.device.uniqueID == device.uniqueID {
                startPlayback(in: current)
                return
            }
            
            await mediaSession.returnToLocalPlayback()?.value
            guard Defaults[.Experimental.chromecast], self.mediaSession === mediaSession,
                  mediaSession.canControlPlayback else { return }

            if !sessions.startSession(with: device) {
                mediaSession.commandError = L10n.castConnectionFailed
            }
        }
    }

    private func startPlayback(in session: GCKCastSession) {
        guard Defaults[.Experimental.chromecast], let mediaSession, mediaSession.canControlPlayback,
              mediaSession.item.mediaType == .video,
              (mediaSession.player as? ChromecastMediaPlayer)?.session !== session else { return }

        mediaSession.transfer(to: ChromecastMediaPlayer(session: session))
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        startPlayback(in: session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didResume session: GCKCastSession) {
        guard Defaults[.Experimental.chromecast], let player = mediaSession?.player as? ChromecastMediaPlayer,
              player.session === session else { return }

        player.connectionResumed()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKCastSession, with reason: GCKConnectionSuspendReason) {
        guard let player = mediaSession?.player as? ChromecastMediaPlayer, player.session === session else { return }

        player.connectionSuspended()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKCastSession) {
        guard let player = mediaSession?.player as? ChromecastMediaPlayer, player.session === session else { return }

        player.connectionSuspended()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        guard let mediaSession, let player = mediaSession.player as? ChromecastMediaPlayer, player.session === session else { return }

        player.sessionEnded(receiverStopped: error == nil)
        
        if error != nil {
            mediaSession.setPlaybackRequestStatus(status: .paused)
        }
        
        mediaSession.returnToLocalPlayback()
        
        if error != nil {
            mediaSession.commandError = L10n.castConnectionFailed
        }
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        mediaSession?.commandError = L10n.castConnectionFailed
    }
}
#endif
