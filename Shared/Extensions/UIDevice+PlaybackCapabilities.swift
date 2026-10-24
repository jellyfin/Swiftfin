//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import UIKit
import VideoToolbox

extension UIDevice {

    enum PlaybackCapabilities {

        /// This property is true if an HDR display is available and the device is capable of playing HDR content.
        static var isDeviceHDRCapable: Bool {
            AVPlayer.eligibleForHDRPlayback
        }

        /// Whether Swiftfin handle Dolby Vision content (`false`) or should it be tone mapped by the server (`true`).
        static var isDolbyVisionEnabled: Bool {
            !StoredValues[.User.forceDVTranscode]
        }

        /// Whether Swiftfin handle HDR content (`false`) or should it be tone mapped by the server (`true`).
        static var isHDREnabled: Bool {
            !StoredValues[.User.forceHDRTranscode]
        }

        static var gpuName: String {
            MTLCreateSystemDefaultDevice()?.name ?? L10n.unknown
        }

        // MARK: - Hardware Decode

        // MARK: MPEG / ITU-T

        /// Whether the device supports hardware-accelerated H.264/AVC decoding.
        static var supportsH264: Bool {
            VTIsHardwareDecodeSupported(kCMVideoCodecType_H264)
        }

        /// Whether the device supports hardware-accelerated H.265/HEVC decoding.
        static var supportsHEVC: Bool {
            VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)
        }

        // MARK: Alliance for Open Media

        /// Whether the device supports hardware-accelerated AV1 decoding.
        ///
        /// - Note: Requires A17 Pro / M3 or newer.
        static var supportsAV1: Bool {
            VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1)
        }

        // MARK: Google

        /// Whether the device supports hardware-accelerated VP9 decoding.
        ///
        /// - Note: VP9 hardware decode is not available on iOS/tvOS.
        static var supportsVP9: Bool {
            VTIsHardwareDecodeSupported(kCMVideoCodecType_VP9)
        }

        // MARK: - HDR

        /// Whether the device can play HDR10 content.
        /// Requires HEVC hardware decode AND HDR-capable display.
        static var supportsHDR10: Bool {
            supportsHEVC && isHDREnabled
        }

        /// Returns true if the device can play HLG content.
        /// Requires HEVC hardware decode AND HDR-capable display.
        static var supportsHLG: Bool {
            supportsHEVC && isHDREnabled
        }

        /// Whether the device supports hardware-accelerated Dolby Vision HEVC decoding.
        /// This correctly distinguishes A10 (no DV) from A10X (DV support).
        static var supportsDolbyVision: Bool {
            VTIsHardwareDecodeSupported(kCMVideoCodecType_DolbyVisionHEVC) && isDolbyVisionEnabled
        }
    }
}
