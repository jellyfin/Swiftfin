//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct DeepLinkURL {
    let type: DeepLinkType
    let path: String

    var url: URL? {
        URL(string: type.rawValue + path)
    }

    var valid: Bool {
        guard let url else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    init(_ urlString: String) {

        let matchedType = DeepLinkType.allCases.first { type in
            urlString.hasPrefix(type.rawValue) && type != .unknown
        } ?? .unknown

        self.type = matchedType
        self.path = urlString
    }

    init(type: DeepLinkType, path: String) {
        self.type = type
        self.path = path
    }
}
