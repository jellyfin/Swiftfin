//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import Nuke
import UIKit

class UserProfileImageViewModel: ViewModel, Eventful, Stateful {

    enum Action: Equatable {
        case cancel
        case upload(UIImage)
    }

    enum Event: Hashable {
        case error(JellyfinAPIError)
        case uploaded
    }

    enum State: Hashable {
        case initial
        case uploading
    }

    @Published
    var state: State = .initial

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var eventSubject: PassthroughSubject<Event, Never> = .init()
    private var uploadCancellable: AnyCancellable?

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            uploadCancellable?.cancel()

            return .initial
        case let .upload(image):

            uploadCancellable = Task {
                do {
                    try await upload(image: image)

                    await MainActor.run {
                        self.eventSubject.send(.uploaded)
                        self.state = .initial
                    }
                } catch is CancellationError {
                    // cancel doesn't matter
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                        self.state = .initial
                    }
                }
            }
            .asAnyCancellable()

            return .uploading
        }
    }

    private func upload(image: UIImage) async throws {

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
            throw JellyfinAPIError("An internal error occurred")
        }

        var request = Paths.postUserImage(
            userID: userSession.user.id,
            imageType: "Primary",
            imageData
        )
        request.headers = ["Content-Type": contentType]

        let _ = try await userSession.client.send(request)

        let currentUserRequest = Paths.getCurrentUser
        let response = try await userSession.client.send(currentUserRequest)

        await MainActor.run {
            userSession.user.data = response.value

            Notifications[.didChangeUserProfileImage].post()
        }
    }
}
