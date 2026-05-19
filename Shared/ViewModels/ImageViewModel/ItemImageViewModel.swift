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

@MainActor
@Stateful
final class ItemImageViewModel: ViewModel {

    @CasePathable
    enum Action {
        case deleteImage(ImageInfo)
        case refresh
        case saveRemoteImage(RemoteImageInfo)
        case uploadFile(file: URL, type: ImageType)
        case uploadImage(image: UIImage, type: ImageType)

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.initial, then: .content)
            case .deleteImage:
                .background(.deleting)
            case .saveRemoteImage, .uploadFile, .uploadImage:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case deleting
        case updating
    }

    enum Event {
        case deleted
        case updated
    }

    enum State {
        case initial
        case content
        case error
    }

    @Published
    var item: BaseItemDto

    @Published
    var images: [ImageType: [ImageInfo]] = [:]

    init(item: BaseItemDto) {
        self.item = item
        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
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

    @Function(\Action.Cases.uploadImage)
    private func _uploadImage(_ image: UIImage, _ type: ImageType) async throws {
        let (imageData, contentType) = try image.data()
        try await upload(imageData: imageData, imageType: type, contentType: contentType)
        try await _refresh()
        events.send(.updated)
    }

    @Function(\Action.Cases.uploadFile)
    private func _uploadFile(_ file: URL, _ type: ImageType) async throws {
        guard file.startAccessingSecurityScopedResource() else {
            logger.error("Unable to access file at \(file)")
            throw ErrorMessage(L10n.unknownError)
        }
        defer { file.stopAccessingSecurityScopedResource() }

        guard let image = try UIImage(data: Data(contentsOf: file)) else {
            logger.error("Unable to create image from file at \(file)")
            throw ErrorMessage(L10n.unknownError)
        }

        try await _uploadImage(image, type)
    }

    private func upload(imageData: Data, imageType: ImageType, contentType: String) async throws {
        guard let itemID = item.id else { return }

        var request = Paths.setItemImage(
            itemID: itemID,
            imageType: imageType.rawValue,
            imageData.base64EncodedData()
        )
        request.headers = ["Content-Type": contentType]

        _ = try await userSession.client.send(request)
    }

    @Function(\Action.Cases.saveRemoteImage)
    private func _saveRemoteImage(_ remoteImageInfo: RemoteImageInfo) async throws {
        guard let itemID = item.id,
              let type = remoteImageInfo.type,
              let imageURL = remoteImageInfo.url else { return }

        let request = Paths.downloadRemoteImage(itemID: itemID, type: type, imageURL: imageURL)

        _ = try await userSession.client.send(request)

        try await _refresh()
        events.send(.updated)
    }

    @Function(\Action.Cases.deleteImage)
    private func _deleteImage(_ deleteImageInfo: ImageInfo) async throws {
        guard let itemID = item.id,
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

        item = try await item.getFullItem(userSession: userSession, sendNotification: true)

        try await _refresh()
        events.send(.deleted)
    }
}
