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

final class UserProfileImageViewModel: ViewModel, Eventful, Stateful {

    // MARK: - Action

    enum Action: Equatable {
        case cancel
        case delete
        case upload(UIImage)
    }

    // MARK: - Event

    enum Event: Hashable {
        case error(ErrorMessage)
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

    let user: UserDto

    // MARK: - Task Variables

    private var eventSubject: PassthroughSubject<Event, Never> = .init()
    private var uploadCancellable: AnyCancellable?

    // MARK: - Initializer

    init(user: UserDto) {
        self.user = user
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

        await MainActor.run {
            Notifications[.didChangeUserProfile].post(userID)
        }
    }

    // MARK: - Delete Image

    private func delete() async throws {

        guard let userID = user.id else { return }

        let request = Paths.deleteUserImage(userID: userID)
        _ = try await userSession.client.send(request)

        sweepProfileImageCache()

        await MainActor.run {
            Notifications[.didChangeUserProfile].post(userID)
        }
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
