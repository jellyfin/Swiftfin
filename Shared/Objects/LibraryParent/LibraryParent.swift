//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

protocol LibraryParent: Displayable, Hashable, Identifiable<String?> {

    /// The type of the library, reusing `BaseItemKind` for some
    /// ease of provided variety like `folder` and `userView`.
    var libraryType: BaseItemKind? { get }

    /// The `BaseItemKind` types that this library parent
    /// support. Mainly used for `.folder` support.
    ///
    /// When using filters, this is used to determine the initial
    /// set of supported types and then
    var supportedItemTypes: [BaseItemKind] { get }

    /// Modifies the parameters for the items request per this library parent.
    func setParentParameters(_ parameters: Paths.GetItemsByUserIDParameters) -> Paths.GetItemsByUserIDParameters
}

extension LibraryParent {

    var supportedItemTypes: [BaseItemKind] {
        switch libraryType {
        case .folder:
            BaseItemKind.supportedCases
                .appending([.folder, .collectionFolder])
        default:
            BaseItemKind.supportedCases
        }
    }

    func setParentParameters(_ parameters: Paths.GetItemsByUserIDParameters) -> Paths.GetItemsByUserIDParameters {

        guard let id else { return parameters }

        var parameters = parameters
        parameters.includeItemTypes = supportedItemTypes

        switch libraryType {
        case .boxSet, .collectionFolder, .userView:
            parameters.parentID = id
        case .folder:
            parameters.parentID = id
            parameters.isRecursive = nil
        case .person:
            parameters.personIDs = [id]
        case .studio:
            parameters.studioIDs = [id]
        default: ()
        }

        return parameters
    }
}
