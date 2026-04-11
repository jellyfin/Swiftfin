//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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
            "Server": [0xC831_8BCA_3734_8B36, 0x78F9_E383_4EC4_0409, 0xC32D_7C44_D347_6825, 0x8593_766E_CEC6_0CFD],
            "User": [0xAE4F_5BDB_1E41_8019, 0x7E5D_7722_D051_7C12, 0x3867_AC59_9F91_A895, 0x6CB9_F896_6ED4_4944],
        ]
    )
}
