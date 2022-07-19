//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension ItemView {

	struct CinematicScrollView<Content: View>: View {

		@ObservedObject
		var viewModel: ItemViewModel

		let content: (ScrollViewProxy) -> Content

		var body: some View {

			ZStack {

				ImageView(viewModel.item.getBackdropImage(maxWidth: 1920),
				          blurHash: viewModel.item.getBackdropImageBlurHash())
					.ignoresSafeArea()

				ScrollView(.vertical, showsIndicators: false) {
					ScrollViewReader { scrollViewProxy in
						content(scrollViewProxy)
					}
				}
				.ignoresSafeArea()
			}
		}
	}
}

extension ItemView {

	struct StaticOverlayView: View {

		enum StaticOverlayFocusLayer: Hashable {
			case playButton
			case actionButton
			case bottomDivider
		}

		@EnvironmentObject
		private var itemRouter: ItemCoordinator.Router
		@ObservedObject
		var viewModel: ItemViewModel

		@State
		var scrollViewProxy: ScrollViewProxy

		@FocusState
		private var focusedLayer: StaticOverlayFocusLayer?

		@EnvironmentObject
		var focusGuide: FocusGuide

		var body: some View {
			VStack {
				Spacer()

				HStack {

					VStack(spacing: 0) {
						ItemView.PlayButton(viewModel: viewModel)
							.padding(.bottom)
							.focused($focusedLayer, equals: .playButton)
							.id("playButton")

						ItemView.ActionButtonHStack(viewModel: viewModel)
							.focusSection()
							.frame(width: 300)
							.focused($focusedLayer, equals: .actionButton)
					}
					.frame(width: 350)

					VStack(alignment: .leading) {
						Text(viewModel.item.displayName)
							.font(.largeTitle)
							.fontWeight(.semibold)
							.lineLimit(2)
							.multilineTextAlignment(.leading)
							.foregroundColor(.white)

						DotHStack {
							if let firstGenre = viewModel.item.genres?.first {
								Text(firstGenre)
							}

							if let premiereYear = viewModel.item.premiereDateYear {
								Text(String(premiereYear))
							}

							if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.getItemRuntime() {
								Text(runtime)
							}
						}
						.font(.caption)
						.foregroundColor(Color(UIColor.lightGray))

						ItemView.AttributesHStack(viewModel: viewModel)
					}

					Spacer(minLength: 0)
				}
				.padding(.horizontal, 50)
			}
		}
	}
}
