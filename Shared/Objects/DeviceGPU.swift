//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Defaults
import VideoToolbox

enum DeviceGPU {

    /// This property is true if an HDR display is available and the device is capable of playing HDR content from an appropriate AVAsset,
    /// false otherwise.
    static var isDisplayHDRCompatible: Bool {
        AVPlayer.eligibleForHDRPlayback
    }

    /// Should Swiftfin handle Dolby Vision content (false) or should it be tone mapped by the server (true)?
    static var dvEnabled: Bool {
        !StoredValues[.User.forceDVTranscode]
    }

    /// Should Swiftfin handle HDR content (false) or should it be tone mapped by the server (true)?
    static var hdrEnabled: Bool {
        !StoredValues[.User.forceHDRTranscode]
    }

    static var displayTitle: String {
        MTLCreateSystemDefaultDevice()?.name ?? L10n.unknown
    }

    // MARK: - Hardware Decode

    // MARK: MPEG / ITU-T

    /// Returns true if the device supports hardware-accelerated H.264/AVC decoding.
    static var supportsH264: Bool {
        VTIsHardwareDecodeSupported(kCMVideoCodecType_H264)
    }

    /// Returns true if the device supports hardware-accelerated H.265/HEVC decoding.
    static var supportsHEVC: Bool {
        VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)
    }

    // MARK: Alliance for Open Media

    /// Returns true if the device supports hardware-accelerated AV1 decoding.
    /// Requires A17 Pro / M3 or newer.
    static var supportsAV1: Bool {
        VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1)
    }

    // MARK: Google

    /// Returns true if the device supports hardware-accelerated VP9 decoding.
    /// Note: VP9 hardware decode is not available on iOS/tvOS.
    static var supportsVP9: Bool {
        VTIsHardwareDecodeSupported(kCMVideoCodecType_VP9)
    }

    // MARK: - HDR

    /// Returns true if the device can play HDR10 content.
    /// Requires HEVC hardware decode AND HDR-capable display.
    /// Note: HDR10 is a transfer function, not a codec—the underlying codec is HEVC.
    static var supportsHDR10: Bool {
        supportsHEVC && hdrEnabled
    }

    /// Returns true if the device can play HLG content.
    /// Requires HEVC hardware decode AND HDR-capable display.
    /// Note: HLG is a transfer function, not a codec—the underlying codec is HEVC.
    static var supportsHLG: Bool {
        supportsHEVC && hdrEnabled
    }

    /// Returns true if the device supports hardware-accelerated Dolby Vision HEVC decoding.
    /// This correctly distinguishes A10 (no DV) from A10X (DV support).
    static var supportsDolbyVision: Bool {
        VTIsHardwareDecodeSupported(kCMVideoCodecType_DolbyVisionHEVC) && dvEnabled
    }
}
