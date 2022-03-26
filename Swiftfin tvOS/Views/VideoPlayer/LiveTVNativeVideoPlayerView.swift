//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

struct LiveTVNativeVideoPlayerView: UIViewControllerRepresentable {

	let viewModel: VideoPlayerViewModel

	typealias UIViewControllerType = NativePlayerViewController

	func makeUIViewController(context: Context) -> NativePlayerViewController {
		NativePlayerViewController(viewModel: viewModel)
	}

	func updateUIViewController(_ uiViewController: NativePlayerViewController, context: Context) {}
}
