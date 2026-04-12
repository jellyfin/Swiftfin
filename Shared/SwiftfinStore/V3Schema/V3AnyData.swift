//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation

extension SwiftfinStore.V3 {

    final class AnyData: CoreStoreObject {

        @Field.Stored("data")
        var data: Data?

        @Field.Stored("domain")
        var domain: String = ""

        @Field.Stored("key")
        var key: String = ""

        @Field.Stored("ownerID")
        var ownerID: String = ""
    }
}
