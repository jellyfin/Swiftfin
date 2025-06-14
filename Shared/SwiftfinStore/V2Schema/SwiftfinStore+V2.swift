//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation

// TODO: complete and make migration

extension SwiftfinStore.V2 {

    static let schema = CoreStoreSchema(
        modelVersion: "V2",
        entities: [
            Entity<StoredServer>("Server"),
            Entity<StoredUser>("User"),
            Entity<AnyData>("AnyData"),
        ],
        versionLock: [
            "AnyData": [0x749D_39C2_219D_4918, 0x9281_539F_1DFB_63E1, 0x293F_D0B7_B64C_E984, 0x8F2F_91F2_33EA_8EB5],
            "Server": [0xABE4_5410_E482_277C, 0x7F28_5358_80C0_1563, 0x3F58_D4B1_CA19_AB2D, 0x5464_E808_90AF_9BB3],
            "User": [0xAE4F_5BDB_1E41_8019, 0x7E5D_7722_D051_7C12, 0x3867_AC59_9F91_A895, 0x6CB9_F896_6ED4_4944],
        ]
    )
}
