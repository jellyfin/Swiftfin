//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI
import UIKit

typealias NotificationKey<Payload> = Notifications.Key<Payload>

extension Container {
    var notificationCenter: Factory<NotificationCenter> {
        self { NotificationCenter.default }.singleton
    }
}

enum Notifications {

    struct Key<Payload>: Hashable {

        @Injected(\.notificationCenter)
        private var notificationService

        let name: Notification.Name

        init(_ name: String) {
            self.name = Notification.Name(name)
        }

        init(_ name: Notification.Name) {
            self.name = name
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }

        static func == (lhs: Key<Payload>, rhs: Key<Payload>) -> Bool {
            lhs.name == rhs.name
        }

        func post(_ payload: Payload) {
            notificationService.post(
                name: name,
                object: nil,
                userInfo: ["payload": payload]
            )
        }

        func subscribe(_ handler: @escaping (Payload) -> Void) -> AnyCancellable {
            notificationService.publisher(for: name)
                .compactMap { notification -> Payload? in
                    return notification.userInfo?["payload"] as? Payload
                }
                .sink { payload in
                    handler(payload)
                }
        }

        func unsubscribe(_ observer: Any) {
            notificationService.removeObserver(observer, name: name, object: nil)
        }

        var publisher: AnyPublisher<Payload, Never> {
            notificationService.publisher(for: name)
                .compactMap { notification -> Payload? in
                    return notification.userInfo?["payload"] as? Payload
                }
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - Keys

extension Notifications {

    // MARK: - Authentication

    static var didSignIn: Key<Void> {
        Key("didSignIn")
    }

    static var didSignOut: Key<Void> {
        Key("didSignOut")
    }

    // MARK: - App Flow

    static var processDeepLink: Key<Void> {
        Key("processDeepLink")
    }

    static var didPurge: Key<Void> {
        Key("didPurge")
    }

    static var didChangeCurrentServerURL: Key<Void> {
        Key("didChangeCurrentServerURL")
    }

    static var didSendStopReport: Key<Void> {
        Key("didSendStopReport")
    }

    static var didRequestGlobalRefresh: Key<Void> {
        Key("didRequestGlobalRefresh")
    }

    static var didFailMigration: Key<Void> {
        Key("didFailMigration")
    }

    // MARK: - Media Items

    static var itemMetadataDidChange: Key<BaseItemDto> {
        Key("itemMetadataDidChange")
    }

    static var itemShouldRefresh: Key<(itemID: String, parentID: String?)> {
        Key("itemShouldRefresh")
    }

    static var didDeleteItem: Key<String> {
        Key("didDeleteItem")
    }

    // MARK: - Server

    static var didConnectToServer: Key<Void> {
        Key("didConnectToServer")
    }

    static var didDeleteServer: Key<Void> {
        Key("didDeleteServer")
    }

    // MARK: - User

    static var didChangeUserProfileImage: Key<Void> {
        Key("didChangeUserProfileImage")
    }

    // MARK: - Playback

    static var didStartPlayback: Key<Void> {
        Key("didStartPlayback")
    }

    static var didAddServerUser: Key<Void> {
        Key("didAddServerUser")
    }

    // MARK: - UIApplication

    static var applicationDidEnterBackground: Key<Void> {
        Key(UIApplication.didEnterBackgroundNotification)
    }

    static var applicationWillResignActive: Key<Void> {
        Key(UIApplication.willResignActiveNotification)
    }

    static var applicationWillTerminate: Key<Void> {
        Key(UIApplication.willTerminateNotification)
    }
}
