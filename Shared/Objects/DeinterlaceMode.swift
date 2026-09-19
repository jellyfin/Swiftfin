//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

/// Deinterlace options for the VLC player, mapped to libVLC's
/// `setDeinterlace(state:mode:)`.
///
/// `off`/`auto` are libVLC *state* choices; the remaining cases are the
/// deinterlace *filters* from VLC's `mode_list[]`
/// (`modules/video_filter/deinterlace/deinterlace.h`), in that order. Filter
/// raw values match the libVLC `psz_mode` tokens.
enum DeinterlaceMode: String, CaseIterable, Displayable, Storable {

    case off
    case auto
    case discard
    case blend
    case mean
    case bob
    case linear
    case x
    case yadif
    case yadif2x
    case phosphor
    case ivtc

    var displayTitle: String {
        switch self {
        case .off: L10n.disabled
        case .auto: L10n.auto
        case .discard: L10n.discard
        case .blend: L10n.blend
        case .mean: L10n.mean
        case .bob: L10n.bob
        case .linear: L10n.linear
        case .x: L10n.deinterlaceX
        case .yadif: L10n.yadif
        case .yadif2x: L10n.yadif2x
        case .phosphor: L10n.phosphor
        case .ivtc: L10n.ivtc
        }
    }

    /// libVLC deinterlace state: `-1` auto, `0` off, `1` on (a specific filter).
    var vlcState: Int {
        switch self {
        case .off: 0
        case .auto: -1
        default: 1
        }
    }

    /// libVLC deinterlace filter name (`psz_mode`), or `nil` for `off`/`auto`.
    var vlcMode: String? {
        switch self {
        case .off, .auto: nil
        default: rawValue
        }
    }
}
