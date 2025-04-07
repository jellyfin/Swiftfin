//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension VideoPlayerType {

    // MARK: direct play

    @ArrayBuilder<DirectPlayProfile>
    static var _swiftfinDirectPlayProfiles: [DirectPlayProfile] {
        DirectPlayProfile(type: .video) {
            AudioCodec.aac
            AudioCodec.ac3
            AudioCodec.alac
            AudioCodec.amr_nb
            AudioCodec.amr_wb
            AudioCodec.dts
            AudioCodec.eac3
            AudioCodec.flac
            AudioCodec.mp1
            AudioCodec.mp2
            AudioCodec.mp3
            AudioCodec.nellymoser
            AudioCodec.opus
            AudioCodec.pcm_alaw
            AudioCodec.pcm_bluray
            AudioCodec.pcm_dvd
            AudioCodec.pcm_mulaw
            AudioCodec.pcm_s16be
            AudioCodec.pcm_s16le
            AudioCodec.pcm_s24be
            AudioCodec.pcm_s24le
            AudioCodec.pcm_u8
            AudioCodec.speex
            AudioCodec.vorbis
            AudioCodec.wavpack
            AudioCodec.wmalossless
            AudioCodec.wmapro
            AudioCodec.wmav1
            AudioCodec.wmav2
        }
    }

    // MARK: transcoding

    @ArrayBuilder<TranscodingProfile>
    static var _swiftfinTranscodingProfiles: [TranscodingProfile] {
        TranscodingProfile(
            isBreakOnNonKeyFrames: true,
            context: .streaming,
            maxAudioChannels: "8",
            minSegments: 2,
            protocol: MediaStreamProtocol.hls,
            type: .video
        ) {
            AudioCodec.aac
            AudioCodec.ac3
            AudioCodec.alac
            AudioCodec.dts
            AudioCodec.eac3
            AudioCodec.flac
            AudioCodec.mp1
            AudioCodec.mp2
            AudioCodec.mp3
            AudioCodec.opus
            AudioCodec.vorbis
        } videoCodecs: {
            VideoCodec.av1
            VideoCodec.h263
            VideoCodec.h264
            VideoCodec.hevc
            VideoCodec.mjpeg
            VideoCodec.mpeg1video
            VideoCodec.mpeg2video
            VideoCodec.mpeg4
            VideoCodec.vc1
            VideoCodec.vp9
        } containers: {
            MediaContainer.mp4
        }
    }

    // MARK: subtitle

    @ArrayBuilder<SubtitleProfile>
    static var _swiftfinSubtitleProfiles: [SubtitleProfile] {
        SubtitleProfile.build(method: .embed) {
            SubtitleFormat.ass
            SubtitleFormat.cc_dec
            SubtitleFormat.dvbsub
            SubtitleFormat.dvdsub
            SubtitleFormat.jacosub
            SubtitleFormat.libzvbi_teletextdec
            SubtitleFormat.mov_text
            SubtitleFormat.mpl2
            SubtitleFormat.pgssub
            SubtitleFormat.pjs
            SubtitleFormat.realtext
            SubtitleFormat.sami
            SubtitleFormat.ssa
            SubtitleFormat.subrip
            SubtitleFormat.subviewer
            SubtitleFormat.subviewer1
            SubtitleFormat.text
            SubtitleFormat.ttml
            SubtitleFormat.vplayer
            SubtitleFormat.vtt
            SubtitleFormat.xsub
        }

        SubtitleProfile.build(method: .external) {
            SubtitleFormat.ass
            SubtitleFormat.dvbsub
            SubtitleFormat.dvdsub
            SubtitleFormat.jacosub
            SubtitleFormat.libzvbi_teletextdec
            SubtitleFormat.mpl2
            SubtitleFormat.pgssub
            SubtitleFormat.pjs
            SubtitleFormat.realtext
            SubtitleFormat.sami
            SubtitleFormat.ssa
            SubtitleFormat.subrip
            SubtitleFormat.subviewer
            SubtitleFormat.subviewer1
            SubtitleFormat.text
            SubtitleFormat.ttml
            SubtitleFormat.vplayer
            SubtitleFormat.vtt
            SubtitleFormat.xsub
        }
    }
}
