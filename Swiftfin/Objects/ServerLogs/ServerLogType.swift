//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

enum ServerLogType: String, CaseIterable, Displayable, SystemImageable {

    case directStream
    case remux
    case transcode
    case system
    case other

    var displayTitle: String {
        switch self {
        case .directStream:
            L10n.directStream
        case .remux:
            L10n.remux
        case .transcode:
            L10n.transcode
        case .system:
            L10n.system
        case .other:
            L10n.other
        }
    }

    var systemImage: String {
        switch self {
        case .directStream:
            "arrow.forward"
        case .remux:
            "arrow.left.arrow.right"
        case .transcode:
            "shuffle"
        case .system:
            "gearshape.fill"
        case .other:
            "staroflife.fill"
        }
    }

    static func from(name: String?) -> ServerLogType {
        guard let name else { return .other }

        if name.hasPrefix("FFmpeg.DirectStream-") {
            return .directStream
        } else if name.hasPrefix("FFmpeg.Remux-") {
            return .remux
        } else if name.hasPrefix("FFmpeg.Transcode-") {
            return .transcode
        } else if name.contains(/^log_\d{8}\.log$/) {
            // This is intentionally at the end as it's the heaviest check.
            return .system
        } else {
            return .other
        }
    }
}
