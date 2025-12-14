//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct RemoteImageLibrary: PagingLibrary {

    struct Environment: Equatable, WithDefaultValue {
        var includeAllLanguages: Bool = false
        var provider: String?

        static var `default`: Self { .init() }
    }

    let imageType: ImageType
    let parent: _TitledLibraryParent

    // TODO: wrong ids
    init(imageType: ImageType, itemID: String) {
        self.imageType = imageType
        self.parent = .init(
            displayTitle: imageType.displayTitle,
            libraryID: itemID
        )
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [RemoteImageInfo] {
        var parameters = Paths.GetRemoteImagesParameters()
        parameters.isIncludeAllLanguages = environment.includeAllLanguages
        parameters.providerName = environment.provider
        parameters.type = imageType

        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset

        let request = Paths.getRemoteImages(itemID: parent.libraryID, parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.images ?? []
    }
}

struct RemoteImageProvidersLibrary: PagingLibrary {

    let pages: Bool = false
    let parent: _TitledLibraryParent

    // TODO: wrong ids
    init(itemID: String) {
        self.parent = .init(
            displayTitle: "Providers",
            libraryID: itemID
        )
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [ImageProviderInfo] {
        let request = Paths.getRemoteImageProviders(itemID: parent.libraryID)
        let response = try await pageState.userSession.client.send(request)
        return response.value
    }
}

extension ImageProviderInfo: @retroactive Identifiable, LibraryIdentifiable {

    public var id: String? { name }

    var unwrappedIDHashOrZero: Int {
        name?.hashValue ?? 0
    }
}

// TODO: Good example of a multi-library view model, find way to generalize
//       - variadic generics when available?
//       - be like server activity that just subclasses and then encapsulates multiple libraries?
//       - need way to wait for initial results of all libraries

@MainActor
final class RemoteImageInfoViewModel: ObservableObject {

    var remoteImageLibrary: PagingLibraryViewModel<RemoteImageLibrary>
    let remoteImageProvidersLibrary: PagingLibraryViewModel<RemoteImageProvidersLibrary>

    init(itemID: String, imageType: ImageType) {
        self.remoteImageLibrary = .init(
            library: .init(
                imageType: imageType,
                itemID: itemID
            )
        )
        self.remoteImageProvidersLibrary = .init(
            library: .init(itemID: itemID)
        )
    }

    func refresh() {
        remoteImageLibrary.refresh()
        remoteImageProvidersLibrary.refresh()
    }
}
