//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

// MARK: PortraitImageStackable

extension BaseItemDto: PortraitImageStackable {
	public var portraitImageID: String {
		id ?? "no id"
	}

	public func imageURLContsructor(maxWidth: Int) -> URL {
		switch self.itemType {
		case .episode:
			return getSeriesPrimaryImage(maxWidth: maxWidth)
		default:
			return self.getPrimaryImage(maxWidth: maxWidth)
		}
	}

	public var title: String {
		switch self.itemType {
		case .episode:
			return self.seriesName ?? self.name ?? ""
		default:
			return self.name ?? ""
		}
	}

	public var subtitle: String? {
		switch self.itemType {
		case .episode:
			return getEpisodeLocator()
		default:
			return nil
		}
	}

	public var blurHash: String {
		self.getPrimaryImageBlurHash()
	}

	public var failureInitials: String {
		guard let name = self.name else { return "" }
		let initials = name.split(separator: " ").compactMap { String($0).first }
		return String(initials)
	}

	public var showTitle: Bool {
		switch self.itemType {
		case .episode, .series, .movie, .boxset:
			return Defaults[.showPosterLabels]
		default:
			return true
		}
	}
}
