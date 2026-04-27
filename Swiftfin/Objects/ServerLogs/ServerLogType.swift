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

    /// Creates a `ServerLogType` from a log file name
    init(rawValue: String) {
        if rawValue.hasPrefix("FFmpeg.DirectStream-") {
            self = .directStream
        } else if rawValue.hasPrefix("FFmpeg.Remux-") {
            self = .remux
        } else if rawValue.hasPrefix("FFmpeg.Transcode-") {
            self = .transcode
        } else if rawValue.contains(/^log_\d{8}\.log$/) {
            // This is intentionally at the end as it's the heaviest check.
            self = .system
        } else {
            self = .other
        }
    }
}
