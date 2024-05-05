//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI

// MARK: key/domain

extension StoredValues.Keys {

    // Domains for user data
    enum UserDomain: String {

        case library
        case main
    }

    // MARK: keys
    
    /// Construct a key where `ownerID` is the id of the user in the
    /// current user session, or always returns the default if there
    /// isn't a current session user.
    static func CurrentUserKey<Value: Codable>(
        _ name: String?,
        domain: UserDomain,
        default defaultValue: Value
    ) -> Key<Value> {
        guard let name, let currentUser = Container.userSession()?.user else {
            return Key(always: defaultValue)
        }

        return Key(
            name,
            ownerID: currentUser.id,
            domain: domain.rawValue,
            default: defaultValue
        )
    }
    
    static func UserKey<Value: Codable>(
        _ name: String?,
        ownerID: String,
        domain: UserDomain,
        default defaultValue: Value
    ) -> Key<Value> {
        guard let name else {
            return Key(always: defaultValue)
        }

        return Key(
            name,
            ownerID: ownerID,
            domain: domain.rawValue,
            default: defaultValue
        )
    }

    static func UserKey<Value: Codable>(always: Value) -> Key<Value> {
        Key(always: always)
    }
}

// MARK: values

extension StoredValues.Keys {

    enum User {
        static func libraryDisplayType(parentID: String?) -> Key<LibraryDisplayType> {
            if Defaults[.Customization.Library.rememberLayout] {
                CurrentUserKey(
                    parentID,
                    domain: .library,
                    default: Defaults[.Customization.Library.viewType]
                )
            } else {
                UserKey(always: Defaults[.Customization.Library.viewType])
            }
        }

        static func libraryListColumnCount(parentID: String?) -> Key<Int> {
            if Defaults[.Customization.Library.rememberLayout] {
                CurrentUserKey(
                    parentID,
                    domain: .library,
                    default: Defaults[.Customization.Library.listColumnCount]
                )
            } else {
                UserKey(always: Defaults[.Customization.Library.listColumnCount])
            }
        }

        static func libraryPosterType(parentID: String?) -> Key<PosterDisplayType> {
            if Defaults[.Customization.Library.rememberLayout] {
                CurrentUserKey(
                    parentID,
                    domain: .library,
                    default: Defaults[.Customization.Library.posterType]
                )
            } else {
                UserKey(always: Defaults[.Customization.Library.posterType])
            }
        }

        // Doesn't use `CurrentUserKey` because user data may be
        // retrieved and stored without a user session
        static func data(id: String) -> Key<UserDto> {
            UserKey(
                "userData",
                ownerID: id,
                domain: .main,
                default: .init()
            )
        }
    }
}
