//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

enum DeviceProfileBuilder {

    static func buildProfile(for type: VideoPlayerType, maxBitrate: Int? = nil) -> DeviceProfile {
        let maxStreamingBitrate = maxBitrate
        let maxStaticBitrate = maxBitrate
        let musicStreamingTranscodingBitrate = maxBitrate
        var directPlayProfiles: [DirectPlayProfile] = []
        var transcodingProfiles: [TranscodingProfile] = []
        var codecProfiles: [CodecProfile] = []
        var subtitleProfiles: [SubtitleProfile] = []

        switch type {

        case .swiftfin:
            func buildProfileSwiftfin() {
                // Build direct play profiles
                directPlayProfiles = [
                    // Just make one profile because if VLCKit can't decode it in a certain container, ffmpeg probably can't decode it for
                    // transcode either
                    DirectPlayProfile(
                        // No need to list containers or videocodecs since if jellyfin server can detect it/ffmpeg can decode it, so can
                        // VLCKit
                        // However, list audiocodecs because ffmpeg can decode TrueHD/mlp but VLCKit cannot
                        audioCodec: "flac,alac,aac,eac3,ac3,dts,opus,vorbis,mp3,mp2,mp1,pcm_s24be,pcm_s24le,pcm_s16be,pcm_s16le,pcm_u8,pcm_alaw,pcm_mulaw,pcm_bluray,pcm_dvd,wavpack,wmav2,wmav1,wmapro,wmalossless,nellymoser,speex,amr_nb,amr_wb",
                        type: .video
                    ),
                ]

                // Build transcoding profiles
                // The only cases where transcoding should occur:
                // 1) TrueHD/mlp audio
                // 2) When server forces transcode for bitrate reasons
                transcodingProfiles = [TranscodingProfile(
                    audioCodec: "flac,alac,aac,eac3,ac3,dts,opus,vorbis,mp3,mp2,mp1",
                    // no PCM,wavpack,wmav2,wmav1,wmapro,wmalossless,nellymoser,speex,amr_nb,amr_wb in mp4
                    isBreakOnNonKeyFrames: true,
                    container: "mp4",
                    context: .streaming,
                    maxAudioChannels: "8",
                    minSegments: 2,
                    protocol: "hls",
                    type: .video,
                    videoCodec: "hevc,h264,av1,vp9,vc1,mpeg4,h263,mpeg2video,mpeg1video,mjpeg" // vp8,msmpeg4v3,msmpeg4v2,msmpeg4v1,theora,ffv1,flv1,wmv3,wmv2,wmv1
                    // not supported in mp4
                )]

                // Create subtitle profiles
                subtitleProfiles = [
                    SubtitleProfile(format: "pgssub", method: .embed), // *pgs* normalized to pgssub; includes sup
                    SubtitleProfile(format: "dvdsub", method: .embed),
                    // *dvd* normalized to dvdsub; includes sub/idx I think; microdvd case?
                    SubtitleProfile(format: "subrip", method: .embed), // srt
                    SubtitleProfile(format: "ass", method: .embed),
                    SubtitleProfile(format: "ssa", method: .embed),
                    SubtitleProfile(format: "vtt", method: .embed), // webvtt
                    SubtitleProfile(format: "mov_text", method: .embed), // MPEG-4 Timed Text
                    SubtitleProfile(format: "ttml", method: .embed),
                    SubtitleProfile(format: "text", method: .embed), // txt
                    SubtitleProfile(format: "dvbsub", method: .embed),
                    // dvb_subtitle normalized to dvbsub; burned in during transcode regardless?
                    SubtitleProfile(format: "libzvbi_teletextdec", method: .embed), // dvb_teletext
                    SubtitleProfile(format: "xsub", method: .embed),
                    SubtitleProfile(format: "vplayer", method: .embed),
                    SubtitleProfile(format: "subviewer", method: .embed),
                    SubtitleProfile(format: "subviewer1", method: .embed),
                    SubtitleProfile(format: "sami", method: .embed), // SMI
                    SubtitleProfile(format: "realtext", method: .embed),
                    SubtitleProfile(format: "pjs", method: .embed), // Phoenix Subtitle
                    SubtitleProfile(format: "mpl2", method: .embed),
                    SubtitleProfile(format: "jacosub", method: .embed),
                    SubtitleProfile(format: "cc_dec", method: .embed), // eia_608
                    // Can be passed as external files; ones that jellyfin can encode to must come first
                    SubtitleProfile(format: "subrip", method: .external), // srt
                    SubtitleProfile(format: "ttml", method: .external),
                    SubtitleProfile(format: "vtt", method: .external), // webvtt
                    SubtitleProfile(format: "ass", method: .external),
                    SubtitleProfile(format: "ssa", method: .external),
                    SubtitleProfile(format: "pgssub", method: .external),
                    SubtitleProfile(format: "text", method: .external), // txt
                    SubtitleProfile(format: "dvbsub", method: .external), // dvb_subtitle normalized to dvbsub
                    SubtitleProfile(format: "libzvbi_teletextdec", method: .external), // dvb_teletext
                    SubtitleProfile(format: "dvdsub", method: .external),
                    // *dvd* normalized to dvdsub; includes sub/idx I think; microdvd case?
                    SubtitleProfile(format: "xsub", method: .external),
                    SubtitleProfile(format: "vplayer", method: .external),
                    SubtitleProfile(format: "subviewer", method: .external),
                    SubtitleProfile(format: "subviewer1", method: .external),
                    SubtitleProfile(format: "sami", method: .external), // SMI
                    SubtitleProfile(format: "realtext", method: .external),
                    SubtitleProfile(format: "pjs", method: .external), // Phoenix Subtitle
                    SubtitleProfile(format: "mpl2", method: .external),
                    SubtitleProfile(format: "jacosub", method: .external),
                ]
            }
            buildProfileSwiftfin()

        case .native:
            func buildProfileNative() {
                // Build direct play profiles
                directPlayProfiles = [
                    // Apple limitation: no mp3 in mp4; avi only supports mjpeg with pcm
                    // Right now, mp4 restrictions can't be enforced because mp4, m4v, mov, 3gp,3g2 treated the same
                    DirectPlayProfile(
                        audioCodec: "flac,alac,aac,eac3,ac3,opus",
                        container: "mp4",
                        type: .video,
                        videoCodec: "hevc,h264,mpeg4"
                    ),
                    DirectPlayProfile(
                        audioCodec: "alac,aac,ac3",
                        container: "m4v",
                        type: .video,
                        videoCodec: "h264,mpeg4"
                    ),
                    DirectPlayProfile(
                        audioCodec: "alac,aac,eac3,ac3,mp3,pcm_s24be,pcm_s24le,pcm_s16be,pcm_s16le",
                        container: "mov",
                        type: .video,
                        videoCodec: "hevc,h264,mpeg4,mjpeg"
                    ),
                    DirectPlayProfile(
                        audioCodec: "aac,eac3,ac3,mp3",
                        container: "mpegts",
                        type: .video,
                        videoCodec: "h264"
                    ),
                    DirectPlayProfile(
                        audioCodec: "aac,amr_nb",
                        container: "3gp,3g2",
                        type: .video,
                        videoCodec: "h264,mpeg4"
                    ),
                    DirectPlayProfile(
                        audioCodec: "pcm_s16le,pcm_mulaw",
                        container: "avi",
                        type: .video,
                        videoCodec: "mjpeg"
                    ),
                ]

                // Build transcoding profiles
                transcodingProfiles = [
                    TranscodingProfile(
                        audioCodec: "flac,alac,aac,eac3,ac3,opus",
                        isBreakOnNonKeyFrames: true,
                        container: "mp4",
                        context: .streaming,
                        maxAudioChannels: "8",
                        minSegments: 2,
                        protocol: "hls",
                        type: .video,
                        videoCodec: "hevc,h264,mpeg4"
                    ),
                ]

                // Create subtitle profiles
                subtitleProfiles = [
                    // FFmpeg can only convert bitmap to bitmap and text to text; burn in bitmap subs
                    SubtitleProfile(format: "pgssub", method: .encode),
                    SubtitleProfile(format: "dvdsub", method: .encode),
                    SubtitleProfile(format: "dvbsub", method: .encode),
                    SubtitleProfile(format: "xsub", method: .encode),
                    // According to Apple HLS authoring specs, WebVTT must be in a text file delivered via HLS
                    SubtitleProfile(format: "vtt", method: .hls), // webvtt
                    // Apple HLS authoring spec has closed captions in video segments and TTML in fmp4
                    SubtitleProfile(format: "ttml", method: .embed),
                    SubtitleProfile(format: "cc_dec", method: .embed),
                ]
            }
            buildProfileNative()
        }

        // For now, assume native and VLCKit support same codec conditions:
        let h264CodecConditions: [ProfileCondition] = [
            ProfileCondition(
                condition: .notEquals,
                isRequired: false,
                property: .isAnamorphic,
                value: "true"
            ),
            ProfileCondition(
                condition: .equalsAny,
                isRequired: false,
                property: .videoProfile,
                value: "high|main|baseline|constrained baseline"
            ),
            ProfileCondition(
                condition: .lessThanEqual,
                isRequired: false,
                property: .videoLevel,
                value: "80"
            ),
            ProfileCondition(
                condition: .notEquals,
                isRequired: false,
                property: .isInterlaced,
                value: "true"
            ),
        ]

        codecProfiles.append(CodecProfile(applyConditions: h264CodecConditions, codec: "h264", type: .video))

        let hevcCodecConditions: [ProfileCondition] = [
            ProfileCondition(
                condition: .notEquals,
                isRequired: false,
                property: .isAnamorphic,
                value: "true"
            ),
            ProfileCondition(
                condition: .equalsAny,
                isRequired: false,
                property: .videoProfile,
                value: "high|main|main 10"
            ),
            ProfileCondition(
                condition: .lessThanEqual,
                isRequired: false,
                property: .videoLevel,
                value: "175"
            ),
            ProfileCondition(
                condition: .notEquals,
                isRequired: false,
                property: .isInterlaced,
                value: "true"
            ),
        ]

        codecProfiles.append(CodecProfile(applyConditions: hevcCodecConditions, codec: "hevc", type: .video))

        let responseProfiles: [ResponseProfile] = [ResponseProfile(container: "m4v", mimeType: "video/mp4", type: .video)]

        return .init(
            codecProfiles: codecProfiles,
            containerProfiles: [],
            directPlayProfiles: directPlayProfiles,
            maxStaticBitrate: maxStaticBitrate,
            maxStreamingBitrate: maxStreamingBitrate,
            musicStreamingTranscodingBitrate: musicStreamingTranscodingBitrate,
            responseProfiles: responseProfiles,
            subtitleProfiles: subtitleProfiles,
            transcodingProfiles: transcodingProfiles
        )
    }
}
