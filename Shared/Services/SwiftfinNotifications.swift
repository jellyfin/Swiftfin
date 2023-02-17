//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation

class SwiftfinNotification {

    @Injected(Notifications.service)
    private var notificationService

    private let notificationName: Notification.Name

    fileprivate init(_ notificationName: Notification.Name) {
        self.notificationName = notificationName
    }

    func post(object: Any? = nil) {
        notificationService.post(name: notificationName, object: object)
    }

    func subscribe(_ observer: Any, selector: Selector) {
        notificationService.addObserver(observer, selector: selector, name: notificationName, object: nil)
    }

    func unsubscribe(_ observer: Any) {
        notificationService.removeObserver(self, name: notificationName, object: nil)
    }
}

enum Notifications {

    static let service = Factory(scope: .singleton) { NotificationCenter() }

    final class Key {
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
    static let didChangeServerCurrentURI = NotificationKey("didChangeCurrentLoginURI")
    static let didSendStopReport = NotificationKey("didSendStopReport")
    static let didRequestGlobalRefresh = NotificationKey("didRequestGlobalRefresh")
}
