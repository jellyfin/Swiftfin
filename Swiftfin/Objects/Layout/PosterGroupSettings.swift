//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct PosterGroupSettings: Codable, Hashable {

    private enum CodingKeys: String, CodingKey {

        case displayType
        case size
    }

    var displayType: PosterDisplayType
    var size: PosterDisplayType.Size

    init(
        displayType: PosterDisplayType = .portrait,
        size: PosterDisplayType.Size = .small
    ) {
        self.displayType = displayType
        self.size = size
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayType, forKey: .displayType)

        switch size {
        case .extraSmall: try container.encode("extraSmall", forKey: .size)
        case .small: try container.encode("small", forKey: .size)
        case .medium: try container.encode("medium", forKey: .size)
        case .custom: try container.encode(size, forKey: .size)
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayType = try container.decode(PosterDisplayType.self, forKey: .displayType)

        if let size = try? container.decode(PosterDisplayType.Size.self, forKey: .size) {
            self.size = size
        } else {
            // The original experimental layout stored sizes as strings.
            switch try container.decode(String.self, forKey: .size) {
            case "extraSmall": size = .extraSmall
            case "small": size = .small
            case "medium": size = .medium
            default:
                throw DecodingError.dataCorruptedError(forKey: .size, in: container, debugDescription: "Invalid poster size")
            }
        }
    }

    static let `default` = Self()
    static let resume = Self(displayType: .landscape, size: .medium)
    static let liveTV = Self(displayType: .landscape, size: .small)
}
