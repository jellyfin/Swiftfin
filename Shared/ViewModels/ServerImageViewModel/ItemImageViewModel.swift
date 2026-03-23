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

final class ItemImageViewModel: ServerImageViewModel<BaseItemDto> {

    @Published
    var imageType: ImageType?
    @Published
    var images: [ImageType: [ImageInfo]] = [:]
    @Published
    var remoteImageInfo: RemoteImageInfo?

    init(item: BaseItemDto, imageType: ImageType? = nil) {
        self.imageType = imageType
        super.init(item: item)
    }

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

    private func performUploadFile(_ url: URL, type: ImageType) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Unable to access file at \(url)")
            throw ErrorMessage("An internal error occurred.")
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let contentType: String
        let imageData: Data

        switch url.pathExtension.lowercased() {
        case "png":
            contentType = "image/png"
            imageData = try Data(contentsOf: url)
        case "jpeg", "jpg":
            contentType = "image/jpeg"
            imageData = try Data(contentsOf: url)
        default:
            guard let image = try UIImage(data: Data(contentsOf: url)) else {
                logger.error("Unable to load image from file")
                throw ErrorMessage("An internal error occurred.")
            }

            if let pngData = image.pngData() {
                contentType = "image/png"
                imageData = pngData
            } else if let jpgData = image.jpegData(compressionQuality: 1) {
                contentType = "image/jpeg"
                imageData = jpgData
            } else {
                logger.error("Failed to convert image to png/jpg")
                throw ErrorMessage("An internal error occurred.")
            }
        }

        guard let itemID = item.id else { return }

        let uploadLimit = 30_000_000

        guard imageData.count <= uploadLimit else {
            throw ErrorMessage(
                "This image (\(imageData.count.formatted(.byteCount(style: .file)))) exceeds the maximum allowed size for upload (\(uploadLimit.formatted(.byteCount(style: .file)))."
            )
        }

        var request = Paths.setItemImage(
            itemID: itemID,
            imageType: type.rawValue,
            imageData.base64EncodedData()
        )
        request.headers = ["Content-Type": contentType]

        _ = try await userSession.client.send(request)

        await refresh()
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

        await refresh()
    }

    override func performSave() async throws {
        guard let itemID = item.id,
              let remoteImageInfo,
              let type = remoteImageInfo.type,
              let imageURL = remoteImageInfo.url else { return }

        let parameters = Paths.DownloadRemoteImageParameters(type: type, imageURL: imageURL)
        let request = Paths.downloadRemoteImage(itemID: itemID, parameters: parameters)
        _ = try await userSession.client.send(request)

        await refresh()
    }

    override func performDelete() async throws {
        guard let itemID = item.id, let imageType else { return }

        if let imageIndex = images[imageType]?.first?.imageIndex {
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

        // Refresh the item and images
        item = try await item.getFullItem(userSession: userSession, sendNotification: true)

        await refresh()
    }
}
