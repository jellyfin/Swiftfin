//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import NukeUI
import SwiftUI

struct ImageView: View {

	private let sources: [URL]
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
	private func placeholderView() -> some View {
//		Image(uiImage: UIImage(blurHash: blurhash, size: CGSize(width: 8, height: 8)) ??
//			UIImage(blurHash: "001fC^", size: CGSize(width: 8, height: 8))!)
//			.resizable()

		#if os(tvOS)
			ZStack {
				Color.black.ignoresSafeArea()

				ProgressView()
			}
		#else
			ZStack {
				Color.gray.ignoresSafeArea()

				ProgressView()
			}
		#endif
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
		ImageViewBackgroundA(index: 0,
		                     sources: sources,
		                     placeholderView: placeholderView,
		                     failureView: failureImage)
	}
}

// Two image view are necessary to switch between one another to appease the type system
// as a recursive view with itself isn't valid

fileprivate struct ImageViewBackgroundA<PlaceholderView: View, FailureView: View>: View {

	let index: Int
	let sources: [URL]
	let placeholderView: () -> PlaceholderView
	let failureView: () -> FailureView

	var body: some View {
		LazyImage(source: sources[index]) { state in
			if let image = state.image {
				image
			} else if state.error != nil {
				if index + 1 == sources.count {
					failureView()
				} else {
					ImageViewBackgroundB(index: index + 1,
					                     sources: sources,
					                     placeholderView: placeholderView,
					                     failureView: failureView)
				}
			} else {
				placeholderView()
			}
		}
		.pipeline(ImagePipeline(configuration: .withDataCache))
	}
}

fileprivate struct ImageViewBackgroundB<PlaceholderView: View, FailureView: View>: View {

	let index: Int
	let sources: [URL]
	let placeholderView: () -> PlaceholderView
	let failureView: () -> FailureView

	var body: some View {
		LazyImage(source: sources[index]) { state in
			if let image = state.image {
				image
			} else if state.error != nil {
				if index + 1 == sources.count {
					failureView()
				} else {
					ImageViewBackgroundA(index: index + 1,
					                     sources: sources,
					                     placeholderView: placeholderView,
					                     failureView: failureView)
				}
			} else {
				placeholderView()
			}
		}
		.pipeline(ImagePipeline(configuration: .withDataCache))
	}
}
