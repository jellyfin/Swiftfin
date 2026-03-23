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
import Nuke
import UIKit

@MainActor
@Stateful
final class UserProfileImageViewModel: ViewModel {

    @CasePathable
    enum Action {
        case cancel
        case delete
        case upload(UIImage)

        var transition: Transition {
            switch self {
            case .cancel:
                .to(.initial)
            case .delete:
                .loop(.deleting)
            case .upload:
                .loop(.uploading)
            }
        }
    }

    enum Event {
        case deleted
        case uploaded
    }

    enum State {
        case initial
        case deleting
        case error
        case uploading
    }

    @Published
    private(set) var user: UserDto

    init(user: UserDto) {
        self.user = user
    }

    @Function(\Action.Cases.upload)
    private func _upload(_ image: UIImage) async throws {

        guard let userID = user.id else { return }

        let contentType: String
        let imageData: Data

        if let pngData = image.pngData()?.base64EncodedData() {
            contentType = "image/png"
            imageData = pngData
        } else if let jpgData = image.jpegData(compressionQuality: 1)?.base64EncodedData() {
            contentType = "image/jpeg"
            imageData = jpgData
        } else {
            logger.error("Unable to convert given profile image to png/jpg")
            throw ErrorMessage("An internal error occurred")
        }

        var request = Paths.postUserImage(
            userID: userID,
            imageData
        )
        request.headers = ["Content-Type": contentType]

        guard imageData.count <= 30_000_000 else {
            throw ErrorMessage(
                "This profile image is too large (\(imageData.count.formatted(.byteCount(style: .file)))). The upload limit for images is 30 MB."
            )
        }

        _ = try await userSession.client.send(request)

        sweepProfileImageCache()

        Notifications[.didChangeUserProfile].post(userID)

        events.send(.uploaded)
    }

    @Function(\Action.Cases.delete)
    private func _delete() async throws {

        guard let userID = user.id else { return }

        let request = Paths.deleteUserImage(userID: userID)
        _ = try await userSession.client.send(request)

        sweepProfileImageCache()

        Notifications[.didChangeUserProfile].post(userID)

        events.send(.deleted)
    }

    private func sweepProfileImageCache() {
        if let userImageURL = user.profileImageSource(client: userSession.client, maxWidth: 60).url {
            ImagePipeline.Swiftfin.local.removeItem(for: userImageURL)
            ImagePipeline.Swiftfin.posters.removeItem(for: userImageURL)
        }

        if let userImageURL = user.profileImageSource(client: userSession.client, maxWidth: 120).url {
            ImagePipeline.Swiftfin.local.removeItem(for: userImageURL)
            ImagePipeline.Swiftfin.posters.removeItem(for: userImageURL)
        }

        if let userImageURL = user.profileImageSource(client: userSession.client, maxWidth: 150).url {
            ImagePipeline.Swiftfin.local.removeItem(for: userImageURL)
            ImagePipeline.Swiftfin.posters.removeItem(for: userImageURL)
        }
    }
}
