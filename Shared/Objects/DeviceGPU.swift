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

    /// This property is true if an HDR display is available and the device is capable of playing HDR content from an appropriate AVAsset,
    /// false otherwise.
    static var isDisplayHDRCompatible: Bool {
        AVPlayer.eligibleForHDRPlayback
    }

    /// Should Swiftfin handle HDR content (true) or should it be tone mapped by the server (false)?
    static var hdrEnabled: Bool {
        if StoredValues[.User.transcodeOnSDRDisplay] {
            isDisplayHDRCompatible
        } else {
            true
        }
    }

    /// Should Swiftfin handle Dolby Video (P5) content (true) or should it be tone mapped by the server (false)?
    /// - Note: This breaks DV 8.4 files that uses MKV
    static var doviP5Enabled: Bool {
        StoredValues[.User.enableDOVIP5]
    }

    /// Which generation of GPU does this device use?
    static var family: MTLGPUFamily? {
        MTLGPUFamily.current
    }

    static var displayTitle: String {
        MTLCreateSystemDefaultDevice()?.name ?? L10n.unknown
    }
}
