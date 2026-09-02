//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Combine
import FactoryKit
import Foundation
import JellyfinAPI
import UIKit

extension Container {
    var notificationCenter: Factory<NotificationCenter> {
        self { NotificationCenter.default }.singleton
    }
}

enum Notifications {

    typealias Keys = _AnyKey

    class _AnyKey {
        typealias Key = Notifications.Key
    }

    class Key<Payload>: _AnyKey {

        @Injected(\.notificationCenter)
        private var notificationCenter

        let name: Notification.Name
        let decodeStrategy: ([AnyHashable: Any]) -> Payload?

        static func defaultDecodeStrategy(userInfo: [AnyHashable: Any]) -> Payload? {
            if let payload = userInfo["payload"] as? Payload {
                return payload
            }
            return nil
        }

        var rawValue: String {
            name.rawValue
        }

        convenience init(_ string: String) {
            self.init(Notification.Name(string))
        }

        init(
            _ name: Notification.Name,
            decodeStrategy: (([AnyHashable: Any]) -> Payload?)? = nil
        ) {
            self.name = name
            self.decodeStrategy = decodeStrategy ?? Self.defaultDecodeStrategy
        }

        func post(_ payload: Payload) {
            notificationCenter
                .post(
                    name: name,
                    object: nil,
                    userInfo: ["payload": payload]
                )
        }

        func post() where Payload == Void {
            notificationCenter
                .post(
                    name: name,
                    object: nil,
                    userInfo: nil
                )
        }

        var publisher: AnyPublisher<Payload, Never> {
            notificationCenter
                .publisher(for: name)
                .compactMap { output in
                    if Payload.self == Void.self {
                        return () as? Payload
                    }

                    guard let userInfo = output.userInfo else {
                        return nil
                    }

                    return self.decodeStrategy(userInfo)
                }
                .eraseToAnyPublisher()
        }
    }

    static subscript<Payload>(key: Key<Payload>) -> Key<Payload> {
        key
    }
}

// MARK: - Keys

extension Notifications.Key {

    // MARK: - App Flow

    static var didChangeServerConnection: Key<ServerConnection> {
        Key("didChangeServerConnection")
    }

    static var didRequestGlobalRefresh: Key<Void> {
        Key("didRequestGlobalRefresh")
    }

    /// - Payload: The library parent IDs (folders and collection folders) that changed.
    static var didRequestLibraryRefresh: Key<[String]> {
        Key("didRequestLibraryRefresh")
    }

    // MARK: - Items

    static var didDeleteItem: Key<String> {
        Key("didDeleteItem")
    }

    static var didChangeItem: Key<BaseItemDto> {
        Key("didChangeItem")
    }

    /// Pulls the item, then posts `didChangeItem`. Related items arrive from the socket.
    static var getChangedItemUserData: Key<String> {
        Key("getChangedItemUserData")
    }

    /// Pulls the item, then posts `didChangeItem`.
    static var getChangedItemMetadata: Key<String> {
        Key("getChangedItemMetadata")
    }

    // MARK: - Server

    static var didConnectToServer: Key<ServerState> {
        Key("didConnectToServer")
    }

    static var didDeleteServer: Key<ServerState> {
        Key("didDeleteServer")
    }

    static var didServerRestart: Key<Void> {
        Key("didServerRestart")
    }

    // MARK: - Server Users

    static var didDeleteServerUser: Key<String> {
        Key("didDeleteServerUser")
    }

    static var didChangeServerUser: Key<UserDto> {
        Key("didChangeServerUser")
    }

    static var didCreateServerUser: Key<UserDto> {
        Key("didCreateServerUser")
    }

    /// Pulls the user, then posts `didChangeServerUser`.
    static var getChangedUser: Key<String> {
        Key("getChangedUser")
    }

    // MARK: - UIApplication

    static var applicationDidEnterBackground: Key<Void> {
        Key(UIApplication.didEnterBackgroundNotification)
    }

    static var applicationWillEnterForeground: Key<Void> {
        Key(UIApplication.willEnterForegroundNotification)
    }

    static var applicationWillResignActive: Key<Void> {
        Key(UIApplication.willResignActiveNotification)
    }

    static var applicationWillTerminate: Key<Void> {
        Key(UIApplication.willTerminateNotification)
    }

    static var sceneDidEnterBackground: Key<Void> {
        Key(UIScene.didEnterBackgroundNotification)
    }

    static var sceneWillEnterForeground: Key<Void> {
        Key(UIScene.willEnterForegroundNotification)
    }

    static var avAudioSessionInterruption: Key<(AVAudioSession.InterruptionType, AVAudioSession.InterruptionOptions)> {
        Key(AVAudioSession.interruptionNotification) { userInfo in
            guard let rawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: rawValue)
            else {
                return nil
            }
            let options = (userInfo[AVAudioSessionInterruptionOptionKey] as? UInt)
                .map(AVAudioSession.InterruptionOptions.init(rawValue:)) ?? []

            return (type, options)
        }
    }
}
