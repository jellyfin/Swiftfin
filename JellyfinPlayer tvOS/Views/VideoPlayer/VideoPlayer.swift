//
// SwiftFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2021 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct VideoPlayerView: UIViewControllerRepresentable {
	var item: BaseItemDto

	func makeUIViewController(context: Context) -> some UIViewController {

		let storyboard = UIStoryboard(name: "VideoPlayer", bundle: nil)
		let viewController = storyboard.instantiateViewController(withIdentifier: "VideoPlayer") as! VideoPlayerViewController
		viewController.manifest = item

		return viewController
	}

	func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
