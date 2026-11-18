//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

@DefaultDecodable
struct MediaSegmentConfiguration: Hashable, Storable, WithDefaultValue {

    var actions: [MediaSegmentType: MediaSegmentAction] = [.intro: .ask, .outro: .ask]
    var itemTypes: [BaseItemKind] = BaseItemKind.allCases.filter { $0.mediaType == .video && !$0.isLiveStream }
    var skipDelay: Int = 5
    var repeatMode: MediaSegmentRepeatMode = .once
    var shortSegmentAction: MediaSegmentAction = .ask

    subscript(type: MediaSegmentType) -> MediaSegmentAction {
        get {
            actions[type] ?? .off
        }
        set {
            actions[type] = newValue
        }
    }

    func action(for segment: MediaSegment) -> MediaSegmentAction {
        let action = self[segment.type]

        guard action == .skip, segment.end - segment.start < .seconds(skipDelay) else { return action }

        return shortSegmentAction
    }

    static let `default` = MediaSegmentConfiguration()
}
