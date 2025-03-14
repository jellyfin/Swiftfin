//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: 10.10+ Replace with extension of https://github.com/jellyfin/jellyfin-sdk-swift/blob/main/Sources/Entities/VideoRangeType.swift
enum VideoRangeType: String, Displayable {
    /// Unknown video range type.
    case unknown = "Unknown"
    /// SDR video range type (8bit).
    case sdr = "SDR"
    /// HDR10 video range type (10bit).
    case hdr10 = "HDR10"
    /// HLG video range type (10bit).
    case hlg = "HLG"
    /// Dolby Vision video range type (10bit encoded / 12bit remapped).
    case dovi = "DOVI"
    /// Dolby Vision with HDR10 video range fallback (10bit).
    case doviWithHDR10 = "DOVIWithHDR10"
    /// Dolby Vision with HLG video range fallback (10bit).
    case doviWithHLG = "DOVIWithHLG"
    /// Dolby Vision with SDR video range fallback (8bit / 10bit).
    case doviWithSDR = "DOVIWithSDR"
    /// HDR10+ video range type (10bit to 16bit).
    case hdr10Plus = "HDR10Plus"

    /// Initializes from an optional string, defaulting to `.unknown` if nil or invalid.
    init(from rawValue: String?) {
        self = VideoRangeType(rawValue: rawValue ?? "") ?? .unknown
    }

    /// Returns a human-readable display title for each video range type.
    /// Dolby Vision is a proper noun so it is not localized
    var displayTitle: String {
        switch self {
        case .unknown:
            return L10n.unknown
        case .dovi:
            return "Dolby Vision"
        case .doviWithHDR10:
            return "Dolby Vision / HDR10"
        case .doviWithHLG:
            return "Dolby Vision / HLG"
        case .doviWithSDR:
            return "Dolby Vision / SDR"
        case .hdr10Plus:
            return "HDR10+"
        default:
            return self.rawValue
        }
    }

    /// Returns `true` if the video format is HDR (including Dolby Vision).
    var isHDR: Bool {
        switch self {
        case .unknown, .sdr:
            return false
        default:
            return true
        }
    }

    /// Returns `true` if the video format is Dolby Vision.
    var isDolbyVision: Bool {
        switch self {
        case .dovi, .doviWithHDR10, .doviWithHLG, .doviWithSDR:
            return true
        default:
            return false
        }
    }
}
