//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import Get
import JellyfinAPI

struct TubeArchivistLibrary: Identifiable, Hashable {
    let id: String
    let name: String
    let collectionType: CollectionType?
}

enum TubeArchivistLibraryDetector {

    static func fetchLibraries(for userSession: UserSession) async throws -> [TubeArchivistLibrary] {
        guard let url = userSession.client.fullURL(with: "/Library/VirtualFolders") else {
            throw DetectorError.invalidURL
        }

        let request = Request<[VirtualFolder]>(url: url)
        let response = try await userSession.client.send(request)

        return response.value
            .filter { isTubeArchivist(folder: $0) }
            .compactMap { folder in
                guard let id = folder.itemId else { return nil }
                return TubeArchivistLibrary(
                    id: id,
                    name: folder.name,
                    collectionType: folder.collectionType
                )
            }
    }

    static func isTubeArchivist(folder: VirtualFolder) -> Bool {
        guard folder.collectionType == .tvshows else { return false }
        guard let typeOptions = folder.libraryOptions?.typeOptions else { return false }

        return typeOptions.contains { option in
            guard option.type.lowercased() == "series" else { return false }

            let fetchers = option.metadataFetchers + option.imageFetchers
            return fetchers.contains {
                let value = $0.lowercased()
                return value.contains("tubearchivist")
            }
        }
    }
}

// MARK: - Support types

struct VirtualFolder: Decodable {
    let name: String
    let collectionType: CollectionType?
    let libraryOptions: LibraryOptions?
    let itemId: String?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case collectionType = "CollectionType"
        case libraryOptions = "LibraryOptions"
        case itemId = "ItemId"
    }
}

struct LibraryOptions: Decodable {
    let typeOptions: [TypeOption]?

    enum CodingKeys: String, CodingKey {
        case typeOptions = "TypeOptions"
    }
}

struct TypeOption: Decodable {
    let type: String
    let metadataFetchers: [String]
    let imageFetchers: [String]

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case metadataFetchers = "MetadataFetchers"
        case imageFetchers = "ImageFetchers"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        self.metadataFetchers = try container.decodeIfPresent([String].self, forKey: .metadataFetchers) ?? []
        self.imageFetchers = try container.decodeIfPresent([String].self, forKey: .imageFetchers) ?? []
    }
}

enum DetectorError: Error {
    case invalidURL
}
