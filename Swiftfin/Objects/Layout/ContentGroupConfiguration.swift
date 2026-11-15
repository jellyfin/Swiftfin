//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct ContentGroupConfiguration: Codable, Hashable, Identifiable, Displayable, SystemImageable {

    let id: String
    var title: String?
    var source: ContentGroupSource

    init(
        id: String = UUID().uuidString,
        title: String? = nil,
        source: ContentGroupSource
    ) {
        self.id = id
        self.title = title.isNilOrEmpty ? nil : title
        self.source = source
    }

    var displayTitle: String {
        if let title, !title.isEmpty {
            title
        } else {
            source.displayTitle
        }
    }

    var systemImage: String {
        source.systemImage
    }
}
