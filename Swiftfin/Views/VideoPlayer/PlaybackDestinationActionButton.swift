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

        private var selectedDeviceID: String? {
            (mediaSession.player as? ChromecastMediaPlayer)?.session.device.uniqueID
        }

        var body: some View {
            Menu(L10n.cast, systemImage: VideoPlayerActionButton.playbackDestination.systemImage) {
                Button(L10n.playOnThisDevice, systemImage: selectedDeviceID == nil ? "checkmark" : "iphone") {
                    mediaSession.returnToLocalPlayback()
                }
                .disabled(!mediaSession.canReturnToLocalPlayback)

                Divider()

                if let controller, controller.devices.isNotEmpty {
                    ForEach(controller.devices, id: \.uniqueID) { device in
                        Button(
                            device.friendlyName ?? L10n.cast,
                            systemImage: selectedDeviceID == device.uniqueID ? "checkmark" : "tv"
                        ) {
                            controller.select(device, for: mediaSession)
                        }
                        .disabled(!mediaSession.canControlPlayback)
                    }
                } else {
                    Text(L10n.noCastDevicesFound)
                }
            }
            .onAppear {
                guard Defaults[.Experimental.chromecast] else { return }

                let controller = ChromecastController.shared
                self.controller = controller
                controller.startDiscovery()
            }
            .onDisappear {
                controller?.stopDiscovery()
            }
        }
    }
}
#endif
