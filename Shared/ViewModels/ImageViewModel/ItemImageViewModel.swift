//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import UIKit

final class ItemImageViewModel: ImageViewModel<BaseItemDto> {

    @Published
    var images: [ImageType: [ImageInfo]] = [:]

    var imageType: ImageType?
    var remoteImageInfo: RemoteImageInfo?
    var deleteImageInfo: ImageInfo?

    override func performRefresh() async throws {
        guard let itemID = item.id else { return }

        let request = Paths.getItemImageInfos(itemID: itemID)
        let response = try await userSession.client.send(request)

        images = response.value.grouped(by: \.imageType)
            .mapValues { $0.sorted(using: \.imageIndex) }
            .reduce(into: [:]) { partialResult, kv in
                guard let k = kv.key else { return }
                partialResult[k] = kv.value
            }
    }

    override func performUpload(imageData: Data, contentType: String) async throws {
        guard let itemID = item.id, let imageType else { return }

        var request = Paths.setItemImage(
            itemID: itemID,
            imageType: imageType.rawValue,
            imageData
        )
        request.headers = ["Content-Type": contentType]

        _ = try await userSession.client.send(request)

        try await performRefresh()
    }

    override func performSave() async throws {
        guard let itemID = item.id,
              let remoteImageInfo,
              let type = remoteImageInfo.type,
              let imageURL = remoteImageInfo.url else { return }

        let parameters = Paths.DownloadRemoteImageParameters(type: type, imageURL: imageURL)
        let request = Paths.downloadRemoteImage(itemID: itemID, parameters: parameters)

        _ = try await userSession.client.send(request)

        try await performRefresh()
    }

    override func performDelete() async throws {
        guard let itemID = item.id,
              let deleteImageInfo,
              let imageType = deleteImageInfo.imageType else { return }

        if let imageIndex = deleteImageInfo.imageIndex {
            let request = Paths.deleteItemImageByIndex(
                itemID: itemID,
                imageType: imageType.rawValue,
                imageIndex: imageIndex
            )
            try await userSession.client.send(request)
        } else {
            let request = Paths.deleteItemImage(
                itemID: itemID,
                imageType: imageType.rawValue
            )
            try await userSession.client.send(request)
        }

        self.deleteImageInfo = nil

        item = try await item.getFullItem(userSession: userSession, sendNotification: true)

        try await performRefresh()
    }
}
