//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Audio dynamic-range compression ("night mode") for video playback.
///
/// On a TV the dynamic range within a single title is often too wide:
/// dialog is hard to hear and music/effects are jarringly loud. This is
/// *not* loudness normalization between titles (EBU R128 / ReplayGain) —
/// it is dynamic-range compression (DRC) applied to a single stream via
/// libVLC's `compressor` audio filter.
///
/// Each level maps to how hard the compressor works (threshold + ratio,
/// with makeup gain lifting quiet dialog back up). The filter runs
/// client-side on decoded audio, so it applies to both direct-play and
/// transcoded streams.
///
/// Only the Swiftfin (VLC) player supports this; the native (AVPlayer)
/// backend has no equivalent and ignores the setting.
enum AudioNightMode: String, CaseIterable, Displayable, Storable {

    case off
    case gentle
    case medium
    case strong

    var displayTitle: String {
        switch self {
        case .off:
            L10n.off
        case .gentle:
            L10n.nightModeGentle
        case .medium:
            L10n.nightModeMedium
        case .strong:
            L10n.nightModeStrong
        }
    }

    /// libVLC media options that enable and tune the `compressor` audio filter.
    ///
    /// `.off` returns an empty dictionary so playback is bit-identical to
    /// having no compression configured. Keys are colon-prefixed so VLCKit
    /// passes them as per-media input options. Values are strings to avoid
    /// any locale-dependent `NSNumber` formatting.
    ///
    /// Presets are starting points — they should be tuned by ear on real
    /// content. Threshold is in dB (lower = more of the signal compressed),
    /// ratio is the compression ratio, and makeup gain (dB) raises the
    /// quieter, now-compressed signal back to a comfortable level.
    var vlcOptions: [String: Any] {
        guard let preset else { return [:] }

        return [
            ":audio-filter": "compressor",
            ":compressor-threshold": String(preset.thresholdDB),
            ":compressor-ratio": String(preset.ratio),
            ":compressor-makeup-gain": String(preset.makeupGainDB),
        ]
    }

    private var preset: (thresholdDB: Int, ratio: Int, makeupGainDB: Int)? {
        switch self {
        case .off:
            nil
        case .gentle:
            (thresholdDB: -18, ratio: 2, makeupGainDB: 4)
        case .medium:
            (thresholdDB: -24, ratio: 3, makeupGainDB: 7)
        case .strong:
            (thresholdDB: -30, ratio: 4, makeupGainDB: 10)
        }
    }
}
