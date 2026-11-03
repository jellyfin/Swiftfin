//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension DeviceProfile {

    /// Work around Jellyfin bug that has 40 character limit on codec lists in transcoding profiles.
    func limitingTranscodingCodecLists(sourceAudioCodec: String?, sourceVideoCodec: String?) -> DeviceProfile {
        with(self) {
            $0.transcodingProfiles = transcodingProfiles?.compactMap {
                $0.limitingCodecLists(sourceAudioCodec: sourceAudioCodec, sourceVideoCodec: sourceVideoCodec)
            }
        }
    }
}

private extension TranscodingProfile {

    func limitingCodecLists(sourceAudioCodec: String?, sourceVideoCodec: String?) -> TranscodingProfile? {
        do {
            return try with(self) {
                $0.audioCodec = try LegacyCodecList.limit(audioCodec, preserving: sourceAudioCodec)
                $0.videoCodec = try LegacyCodecList.limit(videoCodec, preserving: sourceVideoCodec)
            }
        } catch {
            // Skip profiles whose required codecs exceed the limit.
            return nil
        }
    }
}

private enum LegacyCodecList {

    enum LimitError: Error {
        case essentialCodecsTooLong
    }

    static func limit(_ value: String?, preserving sourceCodec: String?) throws -> String? {
        guard let value, value.count > 40 else { return value }

        var codecs = value.split(separator: ",").map(String.init)
        let sourceCodec = sourceCodec?.lowercased()

        // Remove lower-priority alternatives while keeping the preferred and source codecs.
        while codecs.joined(separator: ",").count > 40 {
            guard let index = codecs.indices.dropFirst().last(where: { codecs[$0].lowercased() != sourceCodec }) else {
                throw LimitError.essentialCodecsTooLong
            }

            codecs.remove(at: index)
        }

        return codecs.joined(separator: ",")
    }
}
