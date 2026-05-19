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
import UIKit

@MainActor
@Stateful
final class UserImageViewModel: ViewModel {

    @CasePathable
    enum Action {
        case delete
        case upload(UIImage)

        var transition: Transition {
            switch self {
            case .delete:
                .background(.deleting)
            case .upload:
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
        case error
    }

    @Published
    var user: UserDto

    init(user: UserDto) {
        self.user = user
        super.init()
    }

    @Function(\Action.Cases.upload)
    private func _upload(_ image: UIImage) async throws {
        guard let userID = user.id else { return }

        let (imageData, contentType) = try image.data()

        var request = Paths.postUserImage(
            userID: userID,
            imageData.base64EncodedData()
        )
        request.headers = ["Content-Type": contentType]

        _ = try await userSession.client.send(request)

        await cleanImageCache()
        events.send(.updated)
    }

    @Function(\Action.Cases.delete)
    private func _delete() async throws {
        guard let userID = user.id else { return }

        let request = Paths.deleteUserImage(userID: userID)
        _ = try await userSession.client.send(request)

        await cleanImageCache()
        events.send(.deleted)
    }

    private func cleanImageCache() async {
        for width: CGFloat in [60, 120, 150] {
            if let url = user.profileImageSource(client: userSession.client, maxWidth: width).url {
                await ImagePipeline.Swiftfin.local.removeItem(for: url)
                await ImagePipeline.Swiftfin.posters.removeItem(for: url)
            }
        }

        if let userID = user.id {
            Notifications[.didChangeUserProfile].post(userID)
        }
    }
}
