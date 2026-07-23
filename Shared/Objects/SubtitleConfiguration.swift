//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SubtitleConfiguration: Hashable, Storable, WithDefaultValue {

    var color: Color
    var fontName: String
    var size: Int

    /// Note: "Noto Sans CJK SC" should be our default as it successfully handles English and non-Romantic
    static let `default`: SubtitleConfiguration = .init(
        color: .white,
        fontName: "Noto Sans CJK SC",
        size: 9
    )

    private enum CodingKeys: String, CodingKey {
        case color
        case fontName
        case size
    }

    init(color: Color, fontName: String, size: Int) {
        self.color = color
        self.fontName = fontName
        self.size = size
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.color = try Color(hex: container.decode(String.self, forKey: .color))
        self.fontName = try container.decode(String.self, forKey: .fontName)
        self.size = try container.decode(Int.self, forKey: .size)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color.hexString, forKey: .color)
        try container.encode(fontName, forKey: .fontName)
        try container.encode(size, forKey: .size)
    }
}
