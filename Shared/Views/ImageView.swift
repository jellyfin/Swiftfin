//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import NukeUI
import SwiftUI

// TODO: update multiple sources so that multiple blurhashes can be taken, clean up

struct ImageView: View {

	@State
	private var sources: [URL]
	private var currentURL: URL? { sources.first }

	private let blurhash: String
	private let failureInitials: String

	init(src: URL, bh: String = "001fC^", failureInitials: String = "") {
		self.sources = [src]
		self.blurhash = bh
		self.failureInitials = failureInitials
	}

	init(sources: [URL], bh: String = "001fC^", failureInitials: String = "") {
		assert(!sources.isEmpty, "Must supply at least one source")

		self.sources = sources
		self.blurhash = bh
		self.failureInitials = failureInitials
	}

	// TODO: fix placeholder hash view
	@ViewBuilder
	private var placeholderView: some View {
		Image(uiImage: UIImage(blurHash: blurhash, size: CGSize(width: 12, height: 12)) ??
			UIImage(blurHash: "001fC^", size: CGSize(width: 12, height: 12))!)
			.resizable()
	}

	@ViewBuilder
	private func failureImage() -> some View {
		ZStack {
			Rectangle()
				.foregroundColor(Color(UIColor.darkGray))

			Text(failureInitials)
				.font(.largeTitle)
				.foregroundColor(.secondary)
				.accessibilityHidden(true)
		}
	}

	var body: some View {
		if let u = currentURL {
			LazyImage(source: u) { state in
				if let image = state.image {
					image
				} else if state.error != nil {
					placeholderView.onAppear { sources.removeFirst() }
				} else {
					placeholderView
				}
			}
			.pipeline(ImagePipeline(configuration: .withDataCache))
			.id(u)
		} else {
			failureImage()
		}
	}
}
