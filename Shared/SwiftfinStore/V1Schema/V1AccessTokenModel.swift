//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation

extension SwiftfinStore.V1 {

    final class StoredAccessToken: CoreStoreObject {

        @Field.Stored("value")
        var value: String = ""

        @Field.Relationship("user")
        var user: StoredUser?
    }
}
