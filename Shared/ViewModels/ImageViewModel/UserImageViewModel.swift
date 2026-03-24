//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Nuke

final class UserImageViewModel: ImageViewModel<UserDto> {

    override func performUpload(imageData: Data, contentType: String) async throws {
        guard let userID = item.id else { return }

        var request = Paths.postUserImage(
            userID: userID,
            imageData
        )
        request.headers = ["Content-Type": contentType]

        _ = try await userSession.client.send(request)

        cleanImageCache()
    }

    override func performDelete() async throws {
        guard let userID = item.id else { return }

        let request = Paths.deleteUserImage(userID: userID)
        _ = try await userSession.client.send(request)

        cleanImageCache()
    }

    private func cleanImageCache() {
        for width: CGFloat in [60, 120, 150] {
            if let url = item.profileImageSource(client: userSession.client, maxWidth: width).url {
                ImagePipeline.Swiftfin.local.removeItem(for: url)
                ImagePipeline.Swiftfin.posters.removeItem(for: url)
            }
        }

        if let userID = item.id {
            Notifications[.didChangeUserProfile].post(userID)
        }
    }
}
