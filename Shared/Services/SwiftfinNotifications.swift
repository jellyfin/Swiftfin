//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation

class SwiftfinNotification {

    @Injected(Notifications.service)
    private var notificationService

    let name: Notification.Name

    fileprivate init(_ notificationName: Notification.Name) {
        self.name = notificationName
    }

    func post(object: Any? = nil) {
        notificationService.post(name: name, object: object)
    }

    func subscribe(_ observer: Any, selector: Selector) {
        notificationService.addObserver(observer, selector: selector, name: name, object: nil)
    }

    func unsubscribe(_ observer: Any) {
        notificationService.removeObserver(self, name: name, object: nil)
    }

    var publisher: NotificationCenter.Publisher {
        notificationService.publisher(for: name)
    }
}

enum Notifications {

    static let service = Factory(scope: .singleton) { NotificationCenter.default }

    struct Key: Hashable {

        static func == (lhs: Notifications.Key, rhs: Notifications.Key) -> Bool {
            lhs.key == rhs.key
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(key)
        }

        typealias NotificationKey = Notifications.Key

        let key: String
        let underlyingNotification: SwiftfinNotification

        init(_ key: String) {
            self.key = key
            self.underlyingNotification = SwiftfinNotification(Notification.Name(key))
        }
    }

    static subscript(key: Key) -> SwiftfinNotification {
        key.underlyingNotification
    }
}

extension Notifications.Key {

    static let didSignIn = NotificationKey("didSignIn")
    static let didSignOut = NotificationKey("didSignOut")
    static let processDeepLink = NotificationKey("processDeepLink")
    static let didPurge = NotificationKey("didPurge")
    static let didChangeCurrentServerURL = NotificationKey("didChangeCurrentServerURL")
    static let didSendStopReport = NotificationKey("didSendStopReport")
    static let didRequestGlobalRefresh = NotificationKey("didRequestGlobalRefresh")
    static let didFailMigration = NotificationKey("didFailMigration")

    static let itemMetadataDidChange = NotificationKey("itemMetadataDidChange")

    static let didConnectToServer = NotificationKey("didConnectToServer")
    static let didDeleteServer = NotificationKey("didDeleteServer")

    static let didChangeUserProfileImage = NotificationKey("didChangeUserProfileImage")
}
