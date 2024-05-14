//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Factory
import Foundation
import JellyfinAPI

typealias AnyStoredData = SwiftfinStore.V2.AnyData
typealias ServerModel = SwiftfinStore.V1.StoredServer
typealias UserModel = SwiftfinStore.V1.StoredUser

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

    static var dataStack: DataStack {
        let _dataStack = DataStack(
            V1.schema,
            V2.schema,
            migrationChain: ["V1", "V2"]
        )

        let storage = SQLiteStore(fileName: "Swiftfin.sqlite")

        _ = _dataStack.addStorage(storage) { result in
            switch result {
            case .success:
                print("Successfully migrated datastack")
            case let .failure(error):
                LogManager.service().error("Failed creating datastack with: \(error.localizedDescription)")
            }
        }

        return _dataStack
    }

//    fileprivate static var _dataStack: DataStack!

//    private(set) static var dataStack: DataStack {
//        get {
//            _dataStack
//        }
//        set {
//            _dataStack = newValue
//        }
//    }

    func setupDataStack() async throws {
        try await withCheckedThrowingContinuation { continuation in
            let _dataStack = DataStack(
                V1.schema,
                V2.schema,
                migrationChain: ["V1", "V2"]
            )

            _ = _dataStack.addStorage(SQLiteStore(fileName: "Swiftfin.sqlite")) { result in
                switch result {
                case .success:
                    print("Successfully migrated datastack")
                    continuation.resume()
                case let .failure(error):
                    LogManager.service().error("Failed creating datastack with: \(error.localizedDescription)")
                    continuation.resume(throwing: JellyfinAPIError("Failed creating datastack with: \(error.localizedDescription)"))
                }
            }
        }
    }

    static let service = Factory<DataStack>(scope: .singleton) {
        SwiftfinStore.dataStack
    }
}
