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

    // MARK: - Action

    enum Action: Equatable {
        case cancel
        case delete
        case upload(UIImage)
    }

    // MARK: - Event

    enum Event: Hashable {
        case error(JellyfinAPIError)
        case deleted
        case uploaded
    }

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case deleting
        case uploading
    }

    @Published
    var state: State = .initial

    // MARK: - Published Values

    @Published
    var userID: String

    // MARK: - Task Variables

    private var eventSubject: PassthroughSubject<Event, Never> = .init()
    private var uploadCancellable: AnyCancellable?

    // MARK: - Initializer

    init(userID: String) {
        self.userID = userID
    }

    // MARK: - Respond to Action

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            uploadCancellable?.cancel()
            return .initial

        case let .upload(image):
            uploadCancellable = Task {
                do {
                    await MainActor.run {
                        self.state = .uploading
                    }

                    try await upload(image)

                    await MainActor.run {
                        self.eventSubject.send(.uploaded)
                        self.state = .initial
                    }
                } catch is CancellationError {
                    // Cancel doesn't matter
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                        self.state = .initial
                    }
                }
            }
            .asAnyCancellable()

            return state

        case .delete:
            uploadCancellable = Task {
                do {
                    await MainActor.run {
                        self.state = .deleting
                    }

                    try await delete()

                    await MainActor.run {
                        self.eventSubject.send(.deleted)
                        self.state = .initial
                    }
                } catch is CancellationError {
                    // Cancel doesn't matter
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                        self.state = .initial
                    }
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Upload Image

    private func upload(_ image: UIImage) async throws {
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
            userID: userID,
            imageType: "Primary",
            imageData
        )
        request.headers = ["Content-Type": contentType]

        let _ = try await userSession.client.send(request)

        await MainActor.run {
            Notifications[.didChangeUserProfile].post(userID)
        }
    }

    // MARK: - Delete Image

    private func delete() async throws {
        let request = Paths.deleteUserImage(
            userID: userID,
            imageType: "Primary"
        )
        let _ = try await userSession.client.send(request)

        await MainActor.run {
            Notifications[.didChangeUserProfile].post(userID)
        }
    }
}
