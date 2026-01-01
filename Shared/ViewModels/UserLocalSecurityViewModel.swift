//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import KeychainSwift

final class UserLocalSecurityViewModel: ViewModel, Eventful {

    enum Event: Hashable {
        case error(ErrorMessage)
        case promptForOldDeviceAuth
        case promptForOldPin
        case promptForNewDeviceAuth
        case promptForNewPin
    }

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    // Will throw and send event if needing to prompt for old auth.
    func checkForOldPolicy() throws {

        let oldPolicy = userSession.user.accessPolicy

        switch oldPolicy {
        case .requireDeviceAuthentication:
            eventSubject.send(.promptForOldDeviceAuth)

            throw ErrorMessage("Prompt for old device auth")
        case .requirePin:
            eventSubject.send(.promptForOldPin)

            throw ErrorMessage("Prompt for old pin")
        case .none: ()
        }
    }

    // Will throw and send event if needing to prompt for new auth.
    func checkFor(newPolicy: UserAccessPolicy) throws {
        switch newPolicy {
        case .requireDeviceAuthentication:
            eventSubject.send(.promptForNewDeviceAuth)
        case .requirePin:
            eventSubject.send(.promptForNewPin)
        case .none: ()
        }
    }

    func check(oldPin: String) throws {

        if let storedPin = keychain.get("\(userSession.user.id)-pin") {
            if oldPin != storedPin {
                eventSubject.send(.error(.init(L10n.incorrectPinForUser(userSession.user.username))))
                throw ErrorMessage("invalid pin")
            }
        }
    }

    func set(newPolicy: UserAccessPolicy, newPin: String, newPinHint: String) {

        if newPolicy == .requirePin {
            keychain.set(newPin, forKey: "\(userSession.user.id)-pin")
        } else {
            keychain.delete("\(userSession.user.id)-pin")
        }

        userSession.user.accessPolicy = newPolicy
        userSession.user.pinHint = newPinHint
    }
}
