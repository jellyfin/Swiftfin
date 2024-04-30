//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Foundation
import JellyfinAPI
import Pulse
import UIKit

typealias ServerModel = SwiftfinStore.V2.StoredServer
typealias UserModel = SwiftfinStore.V2.StoredUser

typealias ServerState = SwiftfinStore.State.Server
typealias UserState = SwiftfinStore.State.User

// MARK: Namespaces

enum SwiftfinStore {

    /// Namespace for V1 objects
    enum V1 {}

    /// Namespace for V2 objects
    enum V2 {}

    /// Namespace for state objects
    enum State {}
}

// MARK: dataStack

extension SwiftfinStore {

    static let dataStack: DataStack = {

        let _dataStack = DataStack(
            //            V1.schema,
            V2.schema
//            migrationChain: ["V1", "V2"]
        )

//        DispatchQueue.main.async {
//            _ = _dataStack.addStorage(SQLiteStore(fileName: "Swiftfin.sqlite", localStorageOptions: .recreateStoreOnModelMismatch)) {
//                result in
//                print(result)
//            }
//        }

        try! _dataStack.addStorageAndWait(SQLiteStore(
            fileName: "Swiftfin.sqlite",
            localStorageOptions: .recreateStoreOnModelMismatch
        ))

        return _dataStack
    }()
}
