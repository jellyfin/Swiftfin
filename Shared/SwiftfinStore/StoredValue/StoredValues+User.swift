//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI

// TODO: also have matching properties on `UserState` that get/set values
// TODO: cleanup/organize

// MARK: keys

extension StoredValues.Keys {

    /// Construct a key where `ownerID` is the id of the user in the
    /// current user session, or always returns the default if there
    /// isn't a current session user.
    static func CurrentUserKey<Value: Codable>(
        _ name: String?,
        domain: String,
        default defaultValue: Value
    ) -> Key<Value> {
        guard let name, let currentUser = Container.shared.currentUserSession()?.user else {
            return Key(always: defaultValue)
        }

        return Key(
            name,
            ownerID: currentUser.id,
            domain: domain,
            default: defaultValue
        )
    }

    static func UserKey<Value: Codable>(
        _ name: String?,
        ownerID: String,
        domain: String,
        default defaultValue: Value
    ) -> Key<Value> {
        guard let name else {
            return Key(always: defaultValue)
        }

        return Key(
            name,
            ownerID: ownerID,
            domain: domain,
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

        // Doesn't use `CurrentUserKey` because data may be
        // retrieved and stored without a user session
        static func accessPolicy(id: String) -> Key<UserAccessPolicy> {
            UserKey(
                "accessPolicy",
                ownerID: id,
                domain: "accessPolicy",
                default: .none
            )
        }

        // Doesn't use `CurrentUserKey` because data may be
        // retrieved and stored without a user session
        static func data(id: String) -> Key<UserDto> {
            UserKey(
                "userData",
                ownerID: id,
                domain: "userData",
                default: .init()
            )
        }

        static var accessPolicy: Key<UserAccessPolicy> {
            CurrentUserKey(
                "currentUserAccessPolicy",
                domain: "currentUserAccessPolicy",
                default: .none
            )
        }

        static func libraryDisplayType(parentID: String?) -> Key<LibraryDisplayType> {
            CurrentUserKey(
                parentID,
                domain: "setting-libraryDisplayType",
                default: Defaults[.Customization.Library.displayType]
            )
        }

        static func libraryListColumnCount(parentID: String?) -> Key<Int> {
            CurrentUserKey(
                parentID,
                domain: "setting-libraryListColumnCount",
                default: Defaults[.Customization.Library.listColumnCount]
            )
        }

        static func libraryPosterType(parentID: String?) -> Key<PosterDisplayType> {
            CurrentUserKey(
                parentID,
                domain: "setting-libraryPosterType",
                default: Defaults[.Customization.Library.posterType]
            )
        }

        // TODO: for now, only used for `sortBy` and `sortOrder`. Need to come up with
        //       rules for how stored filters work with libraries that should init
        //       with non-default filters (atow ex: favorites)
        static func libraryFilters(parentID: String?) -> Key<ItemFilterCollection> {
            CurrentUserKey(
                parentID,
                domain: "setting-libraryFilters",
                default: ItemFilterCollection.default
            )
        }

        static func pinHint(id: String) -> Key<String> {
            UserKey(
                "pinHint",
                ownerID: id,
                domain: "pinHint",
                default: ""
            )
        }

        static var customDeviceProfiles: Key<[CustomDeviceProfile]> {
            CurrentUserKey(
                "customDeviceProfiles",
                domain: "customDeviceProfiles",
                default: []
            )
        }

        static var enableItemEditing: Key<Bool> {
            CurrentUserKey(
                "enableItemEditing",
                domain: "enableItemEditing",
                default: false
            )
        }

        static var enableItemDeletion: Key<Bool> {
            CurrentUserKey(
                "enableItemDeletion",
                domain: "enableItemDeletion",
                default: false
            )
        }

        static var enableCollectionManagement: Key<Bool> {
            CurrentUserKey(
                "enableCollectionManagement",
                domain: "enableCollectionManagement",
                default: false
            )
        }

        static var itemViewAttributes: Key<[ItemViewAttribute]> {
            CurrentUserKey(
                "itemViewAttributes",
                domain: "itemViewAttributes",
                default: ItemViewAttribute.allCases
            )
        }
    }
}
