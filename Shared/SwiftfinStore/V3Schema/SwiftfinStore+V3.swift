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
                0x749D_39C2_219D_4918,
                0x9281_539F_1DFB_63E1,
                0x293F_D0B7_B64C_E984,
                0x8F2F_91F2_33EA_8EB5
            ],
        ]
    )
}
