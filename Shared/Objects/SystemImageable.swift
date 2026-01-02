//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

/// A type that provides a `systemImage`
protocol SystemImageable {

    var systemImage: String { get }
    var secondarySystemImage: String { get }
}

extension SystemImageable {
    var secondarySystemImage: String {
        systemImage
    }
}
