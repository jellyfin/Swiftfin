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

        try await Task.sleep(nanoseconds: 5_000_000_000)

        let request = Paths.postUserImage(
            userID: userSession.user.id,
            imageType: "Primary",
            index: nil,
            image.jpegData(compressionQuality: 1)?.base64EncodedData()
        )

        let _ = try await userSession.client.send(request)
    }
}
