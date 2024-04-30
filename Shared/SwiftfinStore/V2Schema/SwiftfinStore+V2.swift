//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation

extension SwiftfinStore.V2 {

    static let schema = CoreStoreSchema(
        modelVersion: "V2",
        entities: [
            Entity<StoredServer>("Server"),
            Entity<StoredUser>("User"),
        ]
//        versionLock: [
//            "Server": [0xC831_8BCA_3734_8B36, 0x78F9_E383_4EC4_0409, 0xC32D_7C44_D347_6825, 0x8593_766E_CEC6_0CFD],
//            "User": [0x3800_479E_8EF5_2762, 0x1D9D_A1BA_AE56_0121, 0xA13D_17E3_B289_ECD0, 0x241C_0504_DEE1_B848],
//        ]
    )
}
