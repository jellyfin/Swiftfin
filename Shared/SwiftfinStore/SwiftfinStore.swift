//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import CoreStore

enum SwiftfinStore {
    
    enum Models {
        
        final class Server: CoreStoreObject {
            
            @Field.Stored("url")
            var url: String = ""
            
            @Field.Stored("name")
            var name: String = ""
            
            @Field.Stored("id")
            var id: String = ""
            
            @Field.Relationship("users", inverse: \User.$server)
            var users: Set<User>
        }
        
        final class User: CoreStoreObject {
            
            @Field.Stored("name")
            var name: String = ""
            
            @Field.Stored("id")
            var id: String = ""
            
            @Field.Relationship("server")
            var server: Server?
        }
    }
    
    static let dataStack: DataStack = {
        let schema = CoreStoreSchema(modelVersion: "V1",
                                     entities: [
                                        Entity<SwiftfinStore.Models.Server>("Server"),
                                        Entity<SwiftfinStore.Models.User>("User"),
                                     ],
                                     versionLock: nil)
        
        let _dataStack = DataStack(schema)
        try! _dataStack.addStorageAndWait(
            SQLiteStore(
                fileName: "Swiftfin.sqlite",
                localStorageOptions: .recreateStoreOnModelMismatch
            )
        )
        return _dataStack
    }()
}
