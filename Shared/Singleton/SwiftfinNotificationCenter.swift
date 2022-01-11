//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

enum SwiftfinNotificationCenter {

	static let main: NotificationCenter = {
		NotificationCenter()
	}()

	enum Keys {
		static let didSignIn = Notification.Name("didSignIn")
		static let didSignOut = Notification.Name("didSignOut")
		static let processDeepLink = Notification.Name("processDeepLink")
		static let didPurge = Notification.Name("didPurge")
		static let didChangeServerCurrentURI = Notification.Name("didChangeCurrentLoginURI")

		// Send with an item id to check if current item for item views
		static let didSendStopReport = Notification.Name("didSendStopReport")
	}
}
