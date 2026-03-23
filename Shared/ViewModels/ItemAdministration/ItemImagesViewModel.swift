//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

@MainActor
@Stateful
final class ItemImagesViewModel: ViewModel {

    @CasePathable
    enum Action {
        case cancel
        case refresh
        case setImage(RemoteImageInfo)
        case uploadImage(image: UIImage, type: ImageType)
        case uploadFile(file: URL, type: ImageType)
        case deleteImage(ImageInfo)

        var transition: Transition {
            switch self {
            case .cancel:
                .to(.initial)
            case .refresh:
                .to(.initial, then: .content)
                    .whenBackground(.updating)
            case .setImage, .uploadImage, .uploadFile, .deleteImage:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case updating
    }

    enum Event {
        case updated
    }

    enum State {
        case initial
        case content
        case error
    }

    @Published
    private(set) var item: BaseItemDto
    @Published
    var images: [ImageType: [ImageInfo]] = [:]

    init(item: BaseItemDto) {
        self.item = item
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        images.removeAll()
        try await getAllImages()
    }

    // MARK: - Set Image From URL

    @Function(\Action.Cases.setImage)
    private func _setImage(_ remoteImageInfo: RemoteImageInfo) async throws {
        try await performSetImage(remoteImageInfo)
        try await getAllImages()
        events.send(.updated)
    }

    // MARK: - Upload Image

    @Function(\Action.Cases.uploadImage)
    private func _uploadImage(_ image: UIImage, _ type: ImageType) async throws {
        try await uploadPhoto(image, type: type)
        try await getAllImages()
        events.send(.updated)
    }

    // MARK: - Upload File

    @Function(\Action.Cases.uploadFile)
    private func _uploadFile(_ file: URL, _ type: ImageType) async throws {
        try await performUploadFile(file, type: type)
        try await getAllImages()
        events.send(.updated)
    }

    // MARK: - Delete Image

    @Function(\Action.Cases.deleteImage)
    private func _deleteImage(_ imageInfo: ImageInfo) async throws {
        try await performDeleteImage(imageInfo)
        item = try await item.getFullItem(userSession: userSession, sendNotification: true)
        events.send(.updated)
    }

    // MARK: - Get All Item Images

    private func getAllImages() async throws {
        guard let itemID = item.id else { return }

        let request = Paths.getItemImageInfos(itemID: itemID)
        let response = try await self.userSession.client.send(request)

        images = response.value.grouped(by: \.imageType)
            .mapValues { $0.sorted(using: \.imageIndex) }
            .reduce(into: [:]) { partialResult, kv in
                guard let k = kv.key else { return }
                partialResult[k] = kv.value
            }
    }

    private func performSetImage(_ remoteImageInfo: RemoteImageInfo) async throws {
        guard let itemID = item.id,
              let type = remoteImageInfo.type,
              let imageURL = remoteImageInfo.url else { return }

        let parameters = Paths.DownloadRemoteImageParameters(type: type, imageURL: imageURL)
        let imageRequest = Paths.downloadRemoteImage(itemID: itemID, parameters: parameters)
        try await userSession.client.send(imageRequest)
    }

    private func upload(imageData: Data, imageType: ImageType, contentType: String) async throws {
        guard let itemID = item.id else { return }

        let uploadLimit: Int = 30_000_000

        guard imageData.count <= uploadLimit else {
            throw ErrorMessage(
                "This image (\(imageData.count.formatted(.byteCount(style: .file)))) exceeds the maximum allowed size for upload (\(uploadLimit.formatted(.byteCount(style: .file)))."
            )
        }

        var request = Paths.setItemImage(
            itemID: itemID,
            imageType: imageType.rawValue,
            imageData.base64EncodedData()
        )
        request.headers = ["Content-Type": contentType]

        _ = try await userSession.client.send(request)
    }

    private func uploadPhoto(_ image: UIImage, type: ImageType) async throws {
        let contentType: String
        let imageData: Data

        if let pngData = image.pngData() {
            contentType = "image/png"
            imageData = pngData
        } else if let jpgData = image.jpegData(compressionQuality: 1) {
            contentType = "image/jpeg"
            imageData = jpgData
        } else {
            logger.error("Unable to convert given profile image to png/jpg")
            throw ErrorMessage("An internal error occurred")
        }

        try await upload(
            imageData: imageData,
            imageType: type,
            contentType: contentType
        )
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

        try await upload(
            imageData: imageData,
            imageType: type,
            contentType: contentType
        )
    }

    private func performDeleteImage(_ imageInfo: ImageInfo) async throws {
        guard let itemID = item.id,
              let imageType = imageInfo.imageType else { return }

        if let imageIndex = imageInfo.imageIndex {
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

        try await getAllImages()
    }
}
