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

    static let schema = CoreStoreSchema(
        modelVersion: "V3",
        entities: [
            Entity<AnyData>("AnyData"),
        ],
        versionLock: [
            "AnyData": [
                0xEB43_50DC_85D9_95A4,
                0x1466_51A3_9170_C397,
                0x86C4_769B_AAE9_9CB8,
                0x513A_EBB8_CCC8_D48C
            ]
        ]
    )
}
