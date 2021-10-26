//
// SwiftFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2021 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// MARK: PortraitImageStackable

extension BaseItemDto: PortraitImageStackable {
	public func imageURLContsructor(maxWidth: Int) -> URL {
		getPrimaryImage(maxWidth: maxWidth)
	}

	public var title: String {
		name ?? ""
	}

	public var description: String? {
		switch itemType {
		case .season:
			guard let productionYear = productionYear else { return nil }
			return "\(productionYear)"
		case .episode:
			return getEpisodeLocator()
		default:
			return nil
		}
	}

	public var blurHash: String {
		getPrimaryImageBlurHash()
	}

	public var failureInitials: String {
		guard let name = name else { return "" }
		let initials = name.split(separator: " ").compactMap { String($0).first }
		return String(initials)
	}
}
