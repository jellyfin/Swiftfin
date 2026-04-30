//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Brand names, acronyms, and technical terms that are identical across locales.
/// These live on `L10n` so every display string flows through a single namespace
extension L10n {

    // MARK: - Licenses

    static let mlp2 = "MLP 2.0"

    // MARK: - Video ranges

    static let sdr = "SDR"
    static let hdr = "HDR"
    static let hdr10 = "HDR10"
    static let hdr10Plus = "HDR10+"
    static let hlg = "HLG"
    static let dolbyVision = "Dolby Vision"

    // MARK: - Video codecs

    static let av1 = "AV1"
    static let dirac = "Dirac"
    static let dv = "DV"
    static let ffv1 = "FFV1"
    static let flv1 = "FLV1"
    static let h261 = "H.261"
    static let h263 = "H.263"
    static let h264 = "H.264"
    static let hevc = "HEVC"
    static let mjpeg = "MJPEG"
    static let mpeg1Video = "MPEG-1 Video"
    static let mpeg2Video = "MPEG-2 Video"
    static let mpeg4 = "MPEG-4"
    static let msMpeg4V1 = "MS MPEG-4 v1"
    static let msMpeg4V2 = "MS MPEG-4 v2"
    static let msMpeg4V3 = "MS MPEG-4 v3"
    static let proRes = "ProRes"
    static let theora = "Theora"
    static let vc1 = "VC-1"
    static let vp8 = "VP8"
    static let vp9 = "VP9"
    static let vvc = "VVC"
    static let wmv1 = "WMV1"
    static let wmv2 = "WMV2"
    static let wmv3 = "WMV3"

    // MARK: - Audio codecs

    static let aac = "AAC"
    static let ac3 = "AC-3"
    static let alac = "ALAC"
    static let amrNB = "AMR-NB"
    static let amrWB = "AMR-WB"
    static let dts = "DTS"
    static let dtsHD = "DTS-HD"
    static let eac3 = "E-AC-3"
    static let flac = "FLAC"
    static let mlp = "MLP"
    static let mp1 = "MP1"
    static let mp2 = "MP2"
    static let mp3 = "MP3"
    static let nellymoser = "Nellymoser"
    static let opus = "Opus"
    static let pcmALAW = "PCM ALAW"
    static let pcmBluray = "PCM Bluray"
    static let pcmDVD = "PCM DVD"
    static let pcmMULAW = "PCM MULAW"
    static let pcmS16BE = "PCM S16BE"
    static let pcmS16LE = "PCM S16LE"
    static let pcmS24BE = "PCM S24BE"
    static let pcmS24LE = "PCM S24LE"
    static let pcmU8 = "PCM U8"
    static let speex = "Speex"
    static let trueHD = "TrueHD"
    static let vorbis = "Vorbis"
    static let wavPack = "WavPack"
    static let wmaLossless = "WMA Lossless"
    static let wmaPro = "WMA Pro"
    static let wmaV1 = "WMA V1"
    static let wmaV2 = "WMA V2"

    // MARK: - Containers

    static let avi = "AVI"
    static let flv = "FLV"
    static let m4v = "M4V"
    static let mkv = "MKV"
    static let mov = "MOV"
    static let mp4 = "MP4"
    static let mpegTS = "MPEG-TS"
    static let threeG2 = "3G2"
    static let threeGP = "3GP"
    static let ts = "TS"
    static let webm = "WEBM"

    // MARK: - Subtitle formats

    static let ass = "ASS"
    static let dvbSubtitle = "DVB Subtitle"
    static let dvbTeletext = "DVB Teletext"
    static let dvdSubtitle = "DVD Subtitle"
    static let eia608 = "EIA-608"
    static let jacosub = "Jacosub"
    static let mpeg4TimedText = "MPEG-4 Timed Text"
    static let mpl2 = "MPL2"
    static let pgsSubtitle = "PGS Subtitle"
    static let phoenixSubtitle = "Phoenix Subtitle"
    static let realText = "RealText"
    static let smi = "SMI"
    static let srt = "SRT"
    static let ssa = "SSA"
    static let subViewer = "SubViewer"
    static let subViewer1 = "SubViewer1"
    static let ttml = "TTML"
    static let txt = "TXT"
    static let vPlayer = "VPlayer"
    static let webVTT = "WebVTT"
    static let xsub = "XSUB"

    // MARK: - Brands

    static let swiftfin = "Swiftfin"
    static let jellyfin = "Jellyfin"

    // MARK: - Platforms

    static let iOS = "iOS"
    static let iPadOS = "iPadOS"
    static let macOS = "macOS"
    static let tvOS = "tvOS"

    // MARK: - Clients

    static let android = "Android"
    static let apple = "Apple"
    static let chrome = "Chrome"
    static let edge = "Edge"
    static let edgeChromium = "Edge Chromium"
    static let finamp = "Finamp"
    static let firefox = "Firefox"
    static let homeAssistant = "Home Assistant"
    static let html5 = "HTML5"
    static let internetExplorer = "Internet Explorer"
    static let kodi = "Kodi"
    static let opera = "Opera"
    static let playStation = "PlayStation"
    static let roku = "Roku"
    static let safari = "Safari"
    static let samsungTV = "Samsung TV"
    static let webOS = "WebOS"
    static let windows = "Windows"
    static let xbox = "Xbox"
}
