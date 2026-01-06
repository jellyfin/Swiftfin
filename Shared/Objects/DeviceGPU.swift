//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Defaults

enum DeviceGPU {

    /// This property is YES if an HDR display is available and the device is capable of playing HDR content from an appropriate AVAsset, NO
    /// otherwise. This property does not indicate whether video contains HDR content, whether HDR video is currently playing, or whether
    /// video is playing on an HDR display. This property is not KVO observable.
    static var isDisplayHDRCompatible: Bool {
        AVPlayer.eligibleForHDRPlayback
    }

    static var hdrEnabled: Bool {
        if StoredValues[.User.transcodeOnSDRDisplay] {
            isDisplayHDRCompatible
        } else {
            true
        }
    }

    static var family: MTLGPUFamily? {
        MTLGPUFamily.current
    }

    static var displayTitle: String {
        MTLCreateSystemDefaultDevice()?.name ?? L10n.unknown
    }
}
