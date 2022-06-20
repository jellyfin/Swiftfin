//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PortraitCinematicHeaderView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	@ObservedObject
	private var viewModel: ItemViewModel

	init(viewModel: ItemViewModel) {
		self.viewModel = viewModel
	}

	var body: some View {
		VStack(alignment: .center) {

			Spacer()

			ImageView(viewModel.item.getLogoImage(maxWidth: Int(UIScreen.main.bounds.width)),
			          resizingMode: .aspectFit,
			          failureView: {
			          	Text(viewModel.getItemDisplayName())
			          		.font(.largeTitle)
			          		.fontWeight(.semibold)
			          		.multilineTextAlignment(.center)
			          		.foregroundColor(.white)
			          		.frame(alignment: .bottom)
			          })
			          .frame(height: 100, alignment: .bottom)

            ItemView.DotHStackView()
                .environmentObject(viewModel)

            ItemView.PlayButton(viewModel: viewModel)
                .frame(maxWidth: 300)
                .frame(height: 50)
                .padding(.bottom)
            
            ItemView.ItemActionHStackView()
                .frame(maxWidth: 300)
                .environmentObject(viewModel)
                .padding(.bottom)

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
            
            ItemView.AttributesHStackView()
                .environmentObject(viewModel)
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
