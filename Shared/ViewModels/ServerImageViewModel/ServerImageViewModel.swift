//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import UIKit

@MainActor
@Stateful
class ServerImageViewModel<Item>: ViewModel {

    @CasePathable
    enum Action {
        case cancel
        case refresh
        case delete
        case save
        case upload(UIImage)

        var transition: Transition {
            switch self {
            case .cancel:
                .to(.initial)
            case .refresh:
                .to(.initial, then: .content)
            case .delete:
                .background(.deleting)
            case .save, .upload:
                .background(.updating)
            }
        }
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

    enum BackgroundState {
        case updating
        case deleting
    }

    @Published
    var item: Item

    init(item: Item) {
        self.item = item
        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        try await performRefresh()
        events.send(.updated)
    }

    @Function(\Action.Cases.upload)
    private func _upload(_ image: UIImage) async throws {
        let (imageData, contentType) = try convertImage(image)
        try await performUpload(imageData: imageData, contentType: contentType)
        events.send(.updated)
    }

    @Function(\Action.Cases.save)
    private func _save() async throws {
        try await performSave()
        events.send(.updated)
    }

    @Function(\Action.Cases.delete)
    private func _delete() async throws {
        try await performDelete()
        events.send(.deleted)
    }

    // MARK: - Image Conversion

    /// Converts a `UIImage` to base64-encoded PNG or JPEG data, validated against the 30 MB upload limit.
    func convertImage(_ image: UIImage) throws -> (data: Data, contentType: String) {
        let contentType: String
        let imageData: Data

        if let pngData = image.pngData()?.base64EncodedData() {
            contentType = "image/png"
            imageData = pngData
        } else if let jpgData = image.jpegData(compressionQuality: 1)?.base64EncodedData() {
            contentType = "image/jpeg"
            imageData = jpgData
        } else {
            logger.error("Unable to convert image to png/jpg")
            throw ErrorMessage("An internal error occurred")
        }

        let uploadLimit = 30_000_000

        guard imageData.count <= uploadLimit else {
            throw ErrorMessage(
                "This image is too large (\(imageData.count.formatted(.byteCount(style: .file)))). The upload limit is \(uploadLimit.formatted(.byteCount(style: .file)))."
            )
        }

        return (imageData, contentType)
    }

    // MARK: - Overrides

    func performRefresh() async throws {
        fatalError("Must be overridden in subclass")
    }

    func performUpload(imageData: Data, contentType: String) async throws {
        fatalError("Must be overridden in subclass")
    }

    func performSave() async throws {
        fatalError("Must be overridden in subclass")
    }

    func performDelete() async throws {
        fatalError("Must be overridden in subclass")
    }
}
