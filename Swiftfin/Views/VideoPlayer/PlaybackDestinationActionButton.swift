//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import Defaults
import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct PlaybackDestination: View {

        @Environment(MediaSession.self)
        private var mediaSession

        @State
        private var controller: ChromecastController?

        @State
        private var jellyfinCastController = JellyfinCastController()

        private var selectedDeviceID: String? {
            (mediaSession.player as? ChromecastMediaPlayer)?.session.device.uniqueID
        }

        private var selectedSessionID: String? {
            (mediaSession.player as? JellyfinCastMediaPlayer)?.sessionID
        }

        @ContentBuilder
        var body: some View {
            Menu(L10n.cast, systemImage: VideoPlayerActionButton.playbackDestination.systemImage) {
                Button(L10n.playOnThisDevice, systemImage: mediaSession.isRemotePlayback ? "iphone" : "checkmark") {
                    mediaSession.returnToLocalPlayback()
                }
                .disabled(!mediaSession.canReturnToLocalPlayback)

                Divider()

                if jellyfinCastController.devices.isNotEmpty {
                    Section(L10n.jellyfin) {
                        ForEach(jellyfinCastController.devices, id: \.id) { device in
                            Button(
                                device.deviceName ?? L10n.cast,
                                systemImage: selectedSessionID == device.id ? "checkmark" : "tv"
                            ) {
                                jellyfinCastController.select(device, for: mediaSession)
                            }
                            .disabled(!mediaSession.canControlPlayback)
                        }
                    }
                }

                if let controller, controller.devices.isNotEmpty {
                    Section(L10n.cast) {
                        ForEach(controller.devices, id: \.uniqueID) { device in
                            Button(
                                device.friendlyName ?? L10n.cast,
                                systemImage: selectedDeviceID == device.uniqueID ? "checkmark" : "tv"
                            ) {
                                controller.select(device, for: mediaSession)
                            }
                            .disabled(!mediaSession.canControlPlayback)
                        }
                    }
                } else if jellyfinCastController.devices.isEmpty {
                    Text(L10n.noCastDevicesFound)
                }
            }
            .onAppear {
                jellyfinCastController.startDiscovery()

                guard Defaults[.Experimental.chromecast] else { return }

                let controller = ChromecastController.shared
                self.controller = controller
                controller.startDiscovery()
            }
            .onDisappear {
                jellyfinCastController.stopDiscovery()
                controller?.stopDiscovery()
            }
        }
    }
}
#endif
