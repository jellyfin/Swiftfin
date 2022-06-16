//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Nuke
import NukeUI
import SwiftUI
import UIKit

struct ImageViewSource {
	let url: URL?
	let blurHash: String?

	init(url: URL? = nil, blurHash: String? = nil) {
		self.url = url
		self.blurHash = blurHash
	}
}

struct DefaultFailureView: View {

	var body: some View {
		Color.secondary
	}
}

struct ImageView<FailureView: View>: View {

	@State
	private var sources: [ImageViewSource]
	private var currentURL: URL? { sources.first?.url }
	private var currentBlurHash: String? { sources.first?.blurHash }
	private var failureView: () -> FailureView
	private var resizingMode: ImageResizingMode

	init(_ source: URL?,
	     blurHash: String? = nil,
	     resizingMode: ImageResizingMode = .aspectFill,
	     @ViewBuilder failureView: @escaping () -> FailureView)
	{
		let imageViewSource = ImageViewSource(url: source, blurHash: blurHash)
		_sources = State(initialValue: [imageViewSource])
		self.resizingMode = resizingMode
		self.failureView = failureView
	}

	init(_ source: ImageViewSource,
	     resizingMode: ImageResizingMode = .aspectFill,
	     @ViewBuilder failureView: @escaping () -> FailureView)
	{
		_sources = State(initialValue: [source])
		self.resizingMode = resizingMode
		self.failureView = failureView
	}

	init(_ sources: [ImageViewSource],
	     resizingMode: ImageResizingMode = .aspectFill,
	     @ViewBuilder failureView: @escaping () -> FailureView)
	{
		_sources = State(initialValue: sources)
		self.resizingMode = resizingMode
		self.failureView = failureView
	}

	@ViewBuilder
	private var placeholderView: some View {
		if let currentBlurHash = currentBlurHash {
			BlurHashView(blurHash: currentBlurHash)
				.id(currentBlurHash)
		} else {
			Color.clear
		}
	}

	var body: some View {
		if let currentURL = currentURL {
			LazyImage(source: currentURL) { state in
				if let image = state.image {
					image
						.resizingMode(resizingMode)
				} else if state.error != nil {
					placeholderView.onAppear {
                        LogManager.log.error(state.error?.localizedDescription ?? "--")
                        LogManager.log.error("Could not get image at url: \(sources.first?.url?.absoluteString ?? "--")")
                        sources.removeFirst()
                    }
				} else {
					placeholderView
				}
			}
			.pipeline(ImagePipeline(configuration: .withDataCache))
			.id(currentURL)
		} else {
			failureView()
		}
	}
}

extension ImageView where FailureView == DefaultFailureView {
	init(_ source: URL?, blurHash: String? = nil, resizingMode: ImageResizingMode = .aspectFill) {
		let imageViewSource = ImageViewSource(url: source, blurHash: blurHash)
		self.init(imageViewSource, resizingMode: resizingMode, failureView: { DefaultFailureView() })
	}

	init(_ source: ImageViewSource, resizingMode: ImageResizingMode = .aspectFill) {
		self.init(source, resizingMode: resizingMode, failureView: { DefaultFailureView() })
	}

	init(_ sources: [ImageViewSource], resizingMode: ImageResizingMode = .aspectFill) {
		self.init(sources, resizingMode: resizingMode, failureView: { DefaultFailureView() })
	}

	init(sources: [URL], resizingMode: ImageResizingMode = .aspectFill) {
		let imageViewSources = sources.compactMap { ImageViewSource(url: $0, blurHash: nil) }
		self.init(imageViewSources, resizingMode: resizingMode, failureView: { DefaultFailureView() })
	}
}
