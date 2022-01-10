//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

public protocol PortraitImageStackable {
	func imageURLContsructor(maxWidth: Int) -> URL
	var title: String { get }
	var subtitle: String? { get }
	var blurHash: String { get }
	var failureInitials: String { get }
	var portraitImageID: String { get }
	var showTitle: Bool { get }
}
