//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

	struct CinematicScrollView<ContentView: View>: View {

		@ObservedObject
		var viewModel: ItemViewModel

		let content: () -> ContentView

		@ViewBuilder
		private var headerView: some View {
			ImageView(viewModel.item.getPrimaryImage(maxWidth: Int(UIScreen.main.bounds.width)),
			          blurHash: viewModel.item.getPrimaryImageBlurHash())
		}

		@ViewBuilder
		private var staticOverlayView: some View {
			StaticOverlayView(viewModel: viewModel)
		}

		var body: some View {
			ParallaxHeaderScrollView(header: headerView,
			                         staticOverlayView: staticOverlayView,
			                         headerHeight: UIScreen.main.bounds.height * 0.7) {
				content()
			}
		}
	}
}

extension ItemView.CinematicScrollView {

	struct StaticOverlayView: View {

		@EnvironmentObject
		private var itemRouter: ItemCoordinator.Router
		@ObservedObject
		var viewModel: ItemViewModel

		var body: some View {
			VStack(alignment: .center, spacing: 10) {

				Spacer()

				ImageView(viewModel.item.getLogoImage(maxWidth: Int(UIScreen.main.bounds.width)),
				          resizingMode: .aspectFit,
				          failureView: {
				          	Text(viewModel.item.displayName)
				          		.font(.largeTitle)
				          		.fontWeight(.semibold)
				          		.multilineTextAlignment(.center)
				          		.foregroundColor(.white)
				          		.frame(alignment: .bottom)
				          })
				          .frame(height: 100, alignment: .bottom)

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
                .padding(.horizontal)

				ItemView.PlayButton(viewModel: viewModel)
					.frame(maxWidth: 300)
					.frame(height: 50)

				ItemView.ActionButtonHStack(viewModel: viewModel)
                    .font(.title)
					.frame(maxWidth: 300)
                    .colorScheme(.dark)

				if let firstTagline = viewModel.playButtonItem?.taglines?.first {
					Text(firstTagline)
						.font(.body)
						.fontWeight(.semibold)
						.lineLimit(2)
						.frame(maxWidth: .infinity, alignment: .leading)
						.foregroundColor(.white)
				}

				if let playButtonOverview = viewModel.playButtonItem?.overview {
					TruncatedTextView(playButtonOverview,
					                  lineLimit: 3,
					                  font: UIFont.preferredFont(forTextStyle: .footnote)) {
						itemRouter.route(to: \.itemOverview, viewModel.item)
					}
					.foregroundColor(.white)
				} else if let seriesOverview = viewModel.item.overview {
					TruncatedTextView(seriesOverview,
					                  lineLimit: 3,
					                  font: UIFont.preferredFont(forTextStyle: .footnote)) {
						itemRouter.route(to: \.itemOverview, viewModel.item)
					}
					.foregroundColor(.white)
				}

				HStack {
					ItemView.AttributesHStack(viewModel: viewModel)

					Spacer()
				}
			}
			.padding()
			.background {
				BlurView(style: .systemThinMaterialDark)
					.mask {
						LinearGradient(gradient: Gradient(stops: [
							.init(color: .white, location: 0),
							.init(color: .white, location: 0.2),
							.init(color: .white.opacity(0), location: 1),
						]), startPoint: .bottom, endPoint: .top)
					}
			}
		}
	}
}
