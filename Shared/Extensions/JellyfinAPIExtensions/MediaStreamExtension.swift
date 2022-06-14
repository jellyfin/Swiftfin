//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension MediaStream {
	func externalSubtitleURL(base: String, item: BaseItemDto) -> URL? {
		guard let id = item.id,
		      let index = index,
		      let format = codec else { return nil }
		let startPositionTicks = item.userData?.playbackPositionTicks ?? 0
		let mediaSourceID = id
		return URL(string: "\(base)/Videos/\(id)/\(mediaSourceID)/Subtitles/\(index)/\(startPositionTicks)/Stream.\(format)")
	}
}
