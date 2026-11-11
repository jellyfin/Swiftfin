//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

/// Normalizes Jellyfin identifiers for matching player tracks.
enum MPVTrackIdentity {

    static func subtitleID(_ index: Int) -> String {
        "jellyfin-subtitle-\(index)"
    }

    static func codecName(_ name: String) -> String {
        let name = name.lowercased()

        switch name {
        case "dts_hd":
            return "dts"

        case "dv":
            return "dvvideo"

        case "ssa":
            return "ass"

        case "cc_dec":
            return "eia_608"

        case "dvbsub":
            return "dvb_subtitle"

        case "dvdsub":
            return "dvd_subtitle"

        case "pgssub":
            return "hdmv_pgs_subtitle"

        case "vtt":
            return "webvtt"

        case "srt":
            return "subrip"

        default:
            return name
        }
    }
}
