//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import AVFAudio
import CoreStore
import Defaults
import Logging
import Pulse
import PulseLogHandler
import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    static var orientationLock: UIInterfaceOrientationMask = .all

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        Experimental.swizzleURLSession()

        LoggingSystem.bootstrap { label in

            var loggers: [LogHandler] = [PersistentLogHandler(label: label)]

            #if DEBUG
            loggers.append(SwiftfinConsoleLogger())
            #endif

            return MultiplexLogHandler(loggers)
        }

        CoreStoreDefaults.dataStack = SwiftfinStore.dataStack
        CoreStoreDefaults.logger = SwiftfinCorestoreLogger()

        URLSessionProxyDelegate.enableAutomaticRegistration()

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback)
        } catch {
            print("setting category AVAudioSessionCategoryPlayback failed")
        }

//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setCategory(.playback)
//        } catch {
//            print("setting category AVAudioSessionCategoryPlayback failed")
//        }

        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }

    static func changeOrientation(_ orientation: UIInterfaceOrientationMask) {

        guard UIDevice.isPhone else { return }

        Self.orientationLock = orientation

        if #available(iOS 16, *) {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }
    }
}

extension PersistentLogHandler {

    func settingTrace() -> Self {
        var copy = self
        copy.logLevel = .trace
        return copy
    }
}

extension CoreStore.LogLevel {

    var toSwiftLog: Logger.Level {
        switch self {
        case .trace:
            return .trace
        case .notice:
            return .info
        case .warning:
            return .warning
        case .fatal:
            return .critical
        }
    }
}
