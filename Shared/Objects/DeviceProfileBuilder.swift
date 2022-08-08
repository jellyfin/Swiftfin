//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

// lol can someone buy me a coffee this took forever :|

import AVFoundation
import Defaults
import Foundation
import JellyfinAPI

class DeviceProfileBuilder {
    public var bitrate: Int = 0

    public func setMaxBitrate(bitrate: Int) {
        self.bitrate = bitrate
    }

    public func buildProfile() -> ClientCapabilitiesDeviceProfile {
        let maxStreamingBitrate = bitrate
        let maxStaticBitrate = bitrate
        let musicStreamingTranscodingBitrate = bitrate
        var directPlayProfiles: [DirectPlayProfile] = []
        var transcodingProfiles: [TranscodingProfile] = []
        var codecProfiles: [CodecProfile] = []
        var subtitleProfiles: [SubtitleProfile] = []

        let containerString = "mpegts,mov,mp4,m4v,avi,3gp,3g2"
        var audioCodecString = "aac,mp3,wav,ac3,eac3,opus,amr"
        var videoCodecString = "h264,mpeg4"

        // Supports HEVC?
        if AVURLAsset.isPlayableExtendedMIMEType("video/mp4; codecs=hvc1") {
            videoCodecString = videoCodecString+",hevc"
        }

        // Separate native player profile from VLCKit profile
        if Defaults[.Experimental.nativePlayer] { // Native

            // Build direct play profiles
            directPlayProfiles = [DirectPlayProfile(
                container: containerString,
                audioCodec: audioCodecString,
                videoCodec: videoCodecString,
                type: .video
            )]

            // Build transcoding profiles
            transcodingProfiles = [TranscodingProfile(
                container: "ts",
                type: .video,
                videoCodec: videoCodecString,
                audioCodec: audioCodecString,
                _protocol: "hls",
                context: .streaming,
                maxAudioChannels: "6",
                minSegments: 2,
                breakOnNonKeyFrames: true
            )]

            // Create subtitle profiles
            subtitleProfiles.append(SubtitleProfile(format: "ass", method: .embed))
            subtitleProfiles.append(SubtitleProfile(format: "ssa", method: .embed))
            subtitleProfiles.append(SubtitleProfile(format: "subrip", method: .embed))
            subtitleProfiles.append(SubtitleProfile(format: "sub", method: .embed))
            subtitleProfiles.append(SubtitleProfile(format: "pgssub", method: .embed))
            // These need to be filtered. Most subrips are embedded. I hate subtitles.
            subtitleProfiles.append(SubtitleProfile(format: "subrip", method: .external))
            subtitleProfiles.append(SubtitleProfile(format: "sub", method: .external))
            subtitleProfiles.append(SubtitleProfile(format: "ass", method: .external))
            subtitleProfiles.append(SubtitleProfile(format: "ssa", method: .external))
            subtitleProfiles.append(SubtitleProfile(format: "vtt", method: .external))
            subtitleProfiles.append(SubtitleProfile(format: "ass", method: .external))
            subtitleProfiles.append(SubtitleProfile(format: "ssa", method: .external))

        } else { // VLCKit

            // Build direct play profiles
            directPlayProfiles = [DirectPlayProfile(
                container: containerString+",mkv,webm,ogg,asf,wmv,mpeg,mpg,flv",
                audioCodec: audioCodecString+"alac,flac,dts,vorbis,mp2,mp1,wmav2,pcm_s24le",
                videoCodec: videoCodecString+"h263,flv1,vc1,vp8,vp9,av1,wmv1,wmv2,msmpeg4v2,msmpeg4v3,mpeg2video,theora",
                type: .video
            )]

            // Build transcoding profiles
            transcodingProfiles = [TranscodingProfile(
                container: "ts",
                type: .video,
                videoCodec: videoCodecString+"vc1,vp9,av1,mpeg2video",
                audioCodec: audioCodecString+"dts,mp2,mp1",
                _protocol: "hls",
                context: .streaming,
                maxAudioChannels: "6",
                minSegments: 2,
                breakOnNonKeyFrames: true
            )]

            // Create subtitle profiles
            subtitleProfiles.append(SubtitleProfile(format: "ass", method: .embed))
            subtitleProfiles.append(SubtitleProfile(format: "ssa", method: .embed))
            subtitleProfiles.append(SubtitleProfile(format: "subrip", method: .embed))
            subtitleProfiles.append(SubtitleProfile(format: "sub", method: .embed))
            subtitleProfiles.append(SubtitleProfile(format: "pgssub", method: .embed))
            // These need to be filtered. Most subrips are embedded. I hate subtitles.
            subtitleProfiles.append(SubtitleProfile(format: "subrip", method: .external))
            subtitleProfiles.append(SubtitleProfile(format: "sub", method: .external))
            subtitleProfiles.append(SubtitleProfile(format: "ass", method: .external))
            subtitleProfiles.append(SubtitleProfile(format: "ssa", method: .external))
            subtitleProfiles.append(SubtitleProfile(format: "vtt", method: .external))
            subtitleProfiles.append(SubtitleProfile(format: "ass", method: .external))
            subtitleProfiles.append(SubtitleProfile(format: "ssa", method: .external))

        }
        // Need to check for FLAC, HEVC - what about dolby vision? (dvhe, dvh1, hev1)
        // truehd is not supported by VLCKit or native

        // For now, assume native and VLCKit support same codec conditions:
        let h264CodecConditions: [ProfileCondition] = [
            ProfileCondition(condition: .notEquals, property: .isAnamorphic, value: "true", isRequired: false),
            ProfileCondition(
                condition: .equalsAny,
                property: .videoProfile,
                value: "high|main|baseline|constrained baseline",
                isRequired: false
            ),
            ProfileCondition(condition: .lessThanEqual, property: .videoLevel, value: "80", isRequired: false),
            ProfileCondition(condition: .notEquals, property: .isInterlaced, value: "true", isRequired: false),
        ]
        let hevcCodecConditions: [ProfileCondition] = [
            ProfileCondition(condition: .notEquals, property: .isAnamorphic, value: "true", isRequired: false),
            ProfileCondition(condition: .equalsAny, property: .videoProfile, value: "high|main|main 10", isRequired: false),
            ProfileCondition(condition: .lessThanEqual, property: .videoLevel, value: "175", isRequired: false),
            ProfileCondition(condition: .notEquals, property: .isInterlaced, value: "true", isRequired: false),
        ]

        codecProfiles.append(CodecProfile(type: .video, applyConditions: h264CodecConditions, codec: "h264"))

        if AVURLAsset.isPlayableExtendedMIMEType("video/mp4; codecs=hvc1") {
            codecProfiles.append(CodecProfile(type: .video, applyConditions: hevcCodecConditions, codec: "hevc"))
        }

        let responseProfiles: [ResponseProfile] = [ResponseProfile(container: "m4v", type: .video, mimeType: "video/mp4")]

        let profile = ClientCapabilitiesDeviceProfile(
            maxStreamingBitrate: maxStreamingBitrate,
            maxStaticBitrate: maxStaticBitrate,
            musicStreamingTranscodingBitrate: musicStreamingTranscodingBitrate,
            directPlayProfiles: directPlayProfiles,
            transcodingProfiles: transcodingProfiles,
            containerProfiles: [],
            codecProfiles: codecProfiles,
            responseProfiles: responseProfiles,
            subtitleProfiles: subtitleProfiles
        )

        return profile
    }
}
