//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct TopShelfSnapshot: Codable, Equatable {
    let generatedAt: Date
    let sectionTitle: String
    let userID: String
    let items: [Item]
}

extension TopShelfSnapshot {

    struct Item: Codable, Equatable, Identifiable {
        let id: String
        let title: String
        let imageURL: URL
        let playbackProgress: Double
        let displayURL: URL
        let playURL: URL
    }
}
