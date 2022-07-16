//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

class SwiftfinNotification {

    private let notificationName: Notification.Name

    fileprivate init(_ notificationName: Notification.Name) {
        self.notificationName = notificationName
    }

    func post(object: Any? = nil) {
        Notifications.main.post(name: notificationName, object: object)
    }

    func subscribe(_ observer: Any, selector: Selector) {
        Notifications.main.addObserver(observer, selector: selector, name: notificationName, object: nil)
    }

    func unsubscribe(_ observer: Any) {
        Notifications.main.removeObserver(self, name: notificationName, object: nil)
    }
}

enum Notifications {

    static let main: NotificationCenter = {
        NotificationCenter()
    }()

    final class Key {
        public typealias NotificationKey = Notifications.Key

        public let key: String
        public let underlyingNotification: SwiftfinNotification

        public init(_ key: String) {
            self.key = key
            self.underlyingNotification = SwiftfinNotification(Notification.Name(key))
        }
    }

    static subscript(key: Key) -> SwiftfinNotification {
        key.underlyingNotification
    }

    static func unsubscribe(_ observer: Any) {
        main.removeObserver(observer)
    }
}

extension Notifications.Key {

    static let didSignIn = NotificationKey("didSignIn")
    static let didSignOut = NotificationKey("didSignOut")
    static let processDeepLink = NotificationKey("processDeepLink")
    static let didPurge = NotificationKey("didPurge")
    static let didChangeServerCurrentURI = NotificationKey("didChangeCurrentLoginURI")
    static let toggleOfflineMode = NotificationKey("toggleOfflineMode")
    static let didDeleteOfflineItem = NotificationKey("didDeleteOfflineItem")
    static let didAddDownload = NotificationKey("didAddDownload")
    static let didSendStopReport = NotificationKey("didSendStopReport")
}
