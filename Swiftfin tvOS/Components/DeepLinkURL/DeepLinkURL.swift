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

    // MARK: - Completed DeepLink URL with Prefix

    var url: URL? {
        URL(string: type.prefix + path)
    }

    // MARK: - Verify this URL can be Opened

    var valid: Bool {
        guard let url else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // MARK: - Initialize from a URL String

    init(_ urlString: String) {
        self.type = DeepLinkType.fromURL(urlString)
        self.path = urlString
    }

    // MARK: - Initialize from Valid Components

    init(type: DeepLinkType, path: String) {
        self.type = type
        self.path = path
    }
}
