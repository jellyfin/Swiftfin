//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct PosterConfiguration: Hashable, Storable, WithDefaultValue {

    var indicators: PosterIndicator
    var unplayedStyle: UnplayedIndicatorType
    var useSeriesLandscapeBackdrop: Bool
    var subtitleField: PosterSubtitleField = .none
    var showTitles: Bool = true

    static let `default`: PosterConfiguration = .init(
        indicators: .all,
        unplayedStyle: .indicator,
        useSeriesLandscapeBackdrop: true
    )
}

extension PosterConfiguration {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.indicators = try container.decode(PosterIndicator.self, forKey: .indicators)
        self.showTitles = try container.decodeIfPresent(Bool.self, forKey: .showTitles) ?? true
        self.unplayedStyle = try container.decode(UnplayedIndicatorType.self, forKey: .unplayedStyle)
        self.useSeriesLandscapeBackdrop = try container.decode(Bool.self, forKey: .useSeriesLandscapeBackdrop)
        let subtitleField = try container.decodeIfPresent(String.self, forKey: .subtitleField)
        self.subtitleField = subtitleField.flatMap(PosterSubtitleField.init(rawValue:)) ?? .none
    }
}
