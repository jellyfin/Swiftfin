//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

private extension MediaStream {
    /// Determines if the audio stream is lossless.
    var isLossless: Bool {
        guard type == .audio, let codec = codec?.lowercased() else { return false }
        // List of known lossless audio codecs
        let losslessCodecs: [String] = [
            AudioCodec.flac.rawValue,
            AudioCodec.alac.rawValue,
            AudioCodec.truehd.rawValue,
            AudioCodec.dts_hd.rawValue, // dts-hd ma, dts-hd hra
        ]
        // Check if the codec is in our lossless list or is a PCM format
        return losslessCodecs.contains(where: codec.contains) || codec.starts(with: "pcm")
    }
}

extension VideoPlayerType {

    // MARK: direct play

    @ArrayBuilder<DirectPlayProfile>
    static var _nativeDirectPlayProfiles: [DirectPlayProfile] {
        DirectPlayProfile(type: .video) {
            AudioCodec.eac3 // Dolby Digital Plus (supports Atmos)
            AudioCodec.flac // FLAC lossless (smaller size)
            AudioCodec.alac // Apple Lossless
            AudioCodec.aac // AAC-LC lossy
            AudioCodec.ac3 // Dolby Digital lossy
        } videoCodecs: {
            VideoCodec.hevc // H.265/HEVC (prioritized)
            VideoCodec.h264 // H.264/AVC (HLS spec requirement)
            VideoCodec.mpeg4 // MPEG-4
        } containers: {
            MediaContainer.mp4
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.alac // Apple Lossless (prioritized)
            AudioCodec.aac // AAC-LC
            AudioCodec.ac3 // Dolby Digital
        } videoCodecs: {
            VideoCodec.h264 // H.264/AVC
            VideoCodec.mpeg4 // MPEG-4
        } containers: {
            MediaContainer.m4v
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.eac3 // Dolby Digital Plus (supports Atmos)
            AudioCodec.alac // Apple Lossless
            AudioCodec.pcm_s16le // PCM 16-bit LE (lossless)
            AudioCodec.pcm_s16be // PCM 16-bit BE (lossless)
            AudioCodec.pcm_s24le // PCM 24-bit LE (lossless)
            AudioCodec.pcm_s24be // PCM 24-bit BE (lossless)
            AudioCodec.aac // AAC-LC lossy
            AudioCodec.ac3 // Dolby Digital lossy
            AudioCodec.mp3 // MP3 lossy
        } videoCodecs: {
            VideoCodec.hevc // H.265/HEVC (prioritized)
            VideoCodec.h264 // H.264/AVC
            VideoCodec.mjpeg // Motion JPEG
            VideoCodec.mpeg4 // MPEG-4
        } containers: {
            MediaContainer.mov
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.eac3 // Dolby Digital Plus (supports Atmos)
            AudioCodec.aac // AAC-LC
            AudioCodec.ac3 // Dolby Digital
            AudioCodec.mp3 // MP3
        } videoCodecs: {
            VideoCodec.h264 // H.264/AVC (MPEGTS only supports H.264 per HLS spec)
        } containers: {
            MediaContainer.mpegts
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.aac // AAC-LC
            AudioCodec.amr_nb // AMR-NB
        } videoCodecs: {
            VideoCodec.h264 // H.264/AVC
            VideoCodec.mpeg4 // MPEG-4
        } containers: {
            MediaContainer.threeG2
            MediaContainer.threeGP
        }

        DirectPlayProfile(type: .video) {
            AudioCodec.pcm_s16le // PCM 16-bit LE (lossless, prioritized)
            AudioCodec.pcm_mulaw // PCM mu-law
        } videoCodecs: {
            VideoCodec.mjpeg // Motion JPEG
        } containers: {
            MediaContainer.avi
        }
    }

    // MARK: transcoding

    static func _nativeTranscodingProfiles(for item: BaseItemDto?) -> [TranscodingProfile] {
        let preferLossless = Defaults[Defaults.Keys.VideoPlayer.preferLosslessAudio]
        let preferAtmos = Defaults[Defaults.Keys.VideoPlayer.preferDolbyAtmos]

        // Base order of allowed codecs on Apple devices
        let losslessCodecs: [AudioCodec] = [.flac, .alac]
        let lossyCodecs: [AudioCodec] = [.eac3, .ac3, .aac]
        var orderedCodecs: [AudioCodec] = []

        // Check source streams for capabilities
        let audioStreams = item?.mediaStreams?.filter { $0.type == .audio } ?? []
        let hasLosslessAudio = audioStreams.contains { $0.isLossless }
        let hasAtmosTrack = audioStreams.contains {
            $0.codec?.lowercased() == AudioCodec.eac3.rawValue &&
                ($0.profile?.lowercased().contains("atmos") == true || $0.codecTag?.lowercased() == "ec-3")
        }

        // 1. Set base order based on lossless preference and source content
        if preferLossless && hasLosslessAudio {
            // User wants lossless, and it's available. Prioritize lossless.
            orderedCodecs.append(contentsOf: losslessCodecs)
            orderedCodecs.append(contentsOf: lossyCodecs)
        } else {
            // User wants lossy, or source is only lossy (avoids up-mixing). Prioritize high-quality lossy.
            orderedCodecs.append(contentsOf: lossyCodecs)
            orderedCodecs.append(contentsOf: losslessCodecs)
        }

        // 2. If user prefers Atmos and a suitable track exists, move EAC-3 to the absolute top.
        if preferAtmos && hasAtmosTrack {
            if let index = orderedCodecs.firstIndex(of: .eac3) {
                let eac3 = orderedCodecs.remove(at: index)
                orderedCodecs.insert(eac3, at: 0)
            }
        }

        var profile = TranscodingProfile(
            isBreakOnNonKeyFrames: true,
            context: .streaming,
            enableSubtitlesInManifest: true,
            maxAudioChannels: "8",
            minSegments: 2,
            protocol: MediaStreamProtocol.hls,
            type: .video
        )

        profile.container = MediaContainer.mp4.rawValue
        profile.audioCodec = orderedCodecs.map(\.rawValue).joined(separator: ",")
        profile.videoCodec = [
            VideoCodec.hevc.rawValue,
            VideoCodec.h264.rawValue,
            VideoCodec.mpeg4.rawValue,
        ].joined(separator: ",")

        return [profile]
    }

    // MARK: subtitle

    @ArrayBuilder<SubtitleProfile>
    static var _nativeSubtitleProfiles: [SubtitleProfile] {
        SubtitleProfile.build(method: .embed) {
            SubtitleFormat.cc_dec
            SubtitleFormat.ttml
        }

        SubtitleProfile.build(method: .encode) {
            SubtitleFormat.dvbsub
            SubtitleFormat.dvdsub
            SubtitleFormat.pgssub
            SubtitleFormat.xsub
        }

        SubtitleProfile.build(method: .hls) {
            SubtitleFormat.vtt
        }
    }
}
