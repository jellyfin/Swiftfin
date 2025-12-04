//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin
import XCTest

final class TubeArchivistLibraryDetectorTests: XCTestCase {

    func testIsTubeArchivistPositive() throws {
        let json = """
        {
          "Name": "YouTube",
          "CollectionType": "tvshows",
          "ItemId": "123",
          "LibraryOptions": {
            "TypeOptions": [
              { "Type": "Series", "MetadataFetchers": ["TubeArchivist"], "ImageFetchers": [] }
            ]
          }
        }
        """.data(using: .utf8)!

        let folder = try JSONDecoder().decode(TestVirtualFolder.self, from: json)
        XCTAssertTrue(TubeArchivistLibraryDetector.isTubeArchivist(folder: folder.virtualFolder))
    }

    func testIsTubeArchivistNegativeWrongCollection() throws {
        let json = """
        {
          "Name": "Movies",
          "CollectionType": "movies",
          "ItemId": "456",
          "LibraryOptions": {
            "TypeOptions": [
              { "Type": "Series", "MetadataFetchers": ["TubeArchivist"], "ImageFetchers": [] }
            ]
          }
        }
        """.data(using: .utf8)!

        let folder = try JSONDecoder().decode(TestVirtualFolder.self, from: json)
        XCTAssertFalse(TubeArchivistLibraryDetector.isTubeArchivist(folder: folder.virtualFolder))
    }

    func testIsTubeArchivistPositiveImageFetcher() throws {
        let json = """
        {
          "Name": "YouTube",
          "CollectionType": "tvshows",
          "ItemId": "789",
          "LibraryOptions": {
            "TypeOptions": [
              { "Type": "Series", "MetadataFetchers": [], "ImageFetchers": ["Some", "TubeArchivistMetadata"] }
            ]
          }
        }
        """.data(using: .utf8)!

        let folder = try JSONDecoder().decode(TestVirtualFolder.self, from: json)
        XCTAssertTrue(TubeArchivistLibraryDetector.isTubeArchivist(folder: folder.virtualFolder))
    }
}

private struct TestVirtualFolder: Decodable {
    let virtualFolder: VirtualFolder

    enum CodingKeys: String, CodingKey {
        case virtualFolder = ""
    }
}
