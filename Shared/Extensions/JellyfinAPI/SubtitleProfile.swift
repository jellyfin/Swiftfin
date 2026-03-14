//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension SubtitleProfile {

    init(
        didlMode: String? = nil,
        format: String? = nil,
        language: String? = nil,
        method: SubtitleDeliveryMethod? = nil,
        @ArrayBuilder<SubtitleFormat> containers: () -> String = { "" }
    ) {
        let containers = containers()

        self.init(
            container: containers.isEmpty ? nil : containers,
            didlMode: didlMode,
            format: format,
            language: language,
            method: method
        )
    }

    static func build(
        method: SubtitleDeliveryMethod,
        @ArrayBuilder<SubtitleFormat> containers: () -> [SubtitleFormat]
    ) -> [SubtitleProfile] {
        containers().map {
            SubtitleProfile(container: nil, format: $0.rawValue, method: method)
        }
    }
}
