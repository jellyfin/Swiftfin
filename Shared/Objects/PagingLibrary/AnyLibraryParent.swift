//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct AnyLibraryParent: LibraryParent {

    let displayTitle: String
    let id: String?
    let isRecursiveCollection: Bool
    let libraryType: BaseItemKind?
    let supportedItemTypes: [BaseItemKind]

    init(_ parent: some LibraryParent) {
        self.displayTitle = parent.displayTitle
        self.id = parent.id
        self.isRecursiveCollection = (parent as? BaseItemDto)?.isRecursiveCollection ?? true
        self.libraryType = parent.libraryType
        self.supportedItemTypes = parent.supportedItemTypes
    }

    func setParentParameters(_ parameters: Paths.GetItemsParameters) -> Paths.GetItemsParameters {
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

extension LibraryParent {

    var pagingLibraryID: String {
        id ?? displayTitle
    }
}
