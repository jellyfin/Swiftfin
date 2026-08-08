//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreTransferable
import Foundation
import JellyfinAPI

extension AuthenticationInfo: @retroactive Transferable, TextTransferable {

    public var transferTitle: String {
        appName ?? L10n.unknown
    }

    public var transferBody: String {
        accessToken ?? L10n.unknown
    }
}
