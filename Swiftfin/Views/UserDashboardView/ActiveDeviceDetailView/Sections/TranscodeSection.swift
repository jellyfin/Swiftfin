//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ActiveDeviceDetailView {
    struct TranscodeSection: View {

        let transcodeReasons: [TranscodeReason]

        var body: some View {
            if !transcodeReasons.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    getActiveTranscodeIcons(reasons: transcodeReasons)
                    Divider()
                    getActiveTranscodeReasons(reasons: transcodeReasons)
                }
            }
        }

        @ViewBuilder
        private func getActiveTranscodeIcons(reasons: [TranscodeReason]) -> some View {
            // Ensure the Icons are always in the same order
            let iconOrder: [String] = [
                "speaker.wave.2", // Audio
                "photo.tv", // Video
                "captions.bubble", // Subtitle
                "shippingbox", // Container
                "questionmark.app", // Unknown
            ]

            // Map the Transcoding Reason Icons
            let uniqueIcons = Set(reasons.map { getActiveTranscodeReasons(reason: $0) })
            let transcodeIcons = iconOrder.filter { uniqueIcons.contains($0) }

            // Center the Transcoding Reason Icons for the Header
            HStack {
                Spacer()
                ForEach(Array(transcodeIcons), id: \.self) { icon in
                    Image(systemName: icon)
                        .foregroundColor(.primary)
                }
                Spacer()
            }
        }

        private func getActiveTranscodeReasons(reason: TranscodeReason) -> String {
            switch reason {
            case .containerNotSupported,
                 .containerBitrateExceedsLimit:
                return "shippingbox"
            case .audioCodecNotSupported,
                 .audioIsExternal,
                 .secondaryAudioNotSupported,
                 .audioChannelsNotSupported,
                 .audioProfileNotSupported,
                 .audioSampleRateNotSupported,
                 .audioBitDepthNotSupported,
                 .audioBitrateNotSupported,
                 .unknownAudioStreamInfo:
                return "speaker.wave.2"
            case .videoCodecNotSupported,
                 .videoProfileNotSupported,
                 .videoLevelNotSupported,
                 .videoResolutionNotSupported,
                 .videoBitDepthNotSupported,
                 .videoFramerateNotSupported,
                 .refFramesNotSupported,
                 .anamorphicVideoNotSupported,
                 .interlacedVideoNotSupported,
                 .videoBitrateNotSupported,
                 .unknownVideoStreamInfo,
                 .videoRangeTypeNotSupported:
                return "photo.tv"
            case .subtitleCodecNotSupported:
                return "captions.bubble"
            default:
                return "questionmark.app"
            }
        }

        @ViewBuilder
        private func getActiveTranscodeReasons(reasons: [TranscodeReason]) -> some View {
            VStack(alignment: .center, spacing: 8) {
                ForEach(reasons, id: \.self) { reason in
                    Text(reason.description)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
    }
}
