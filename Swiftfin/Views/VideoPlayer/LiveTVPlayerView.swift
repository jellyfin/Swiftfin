//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

struct LiveTVNativePlayerView: UIViewControllerRepresentable {

	let viewModel: VideoPlayerViewModel

	typealias UIViewControllerType = LiveTVNativePlayerViewController

	func makeUIViewController(context: Context) -> LiveTVNativePlayerViewController {

		LiveTVNativePlayerViewController(viewModel: viewModel)
	}

	func updateUIViewController(_ uiViewController: LiveTVNativePlayerViewController, context: Context) {}
}

struct LiveTVPlayerView: UIViewControllerRepresentable {

	let viewModel: VideoPlayerViewModel

	typealias UIViewControllerType = LiveTVPlayerViewController

	func makeUIViewController(context: Context) -> LiveTVPlayerViewController {

		LiveTVPlayerViewController(viewModel: viewModel)
	}

	func updateUIViewController(_ uiViewController: LiveTVPlayerViewController, context: Context) {}
}
