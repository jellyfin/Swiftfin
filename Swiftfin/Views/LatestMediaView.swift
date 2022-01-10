//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

struct LatestMediaView<TopBarView: View>: View {

	@EnvironmentObject
	var homeRouter: HomeCoordinator.Router
	@StateObject
	var viewModel: LatestMediaViewModel
	var topBarView: () -> TopBarView

	var body: some View {
		PortraitImageHStackView(items: viewModel.items,
		                        horizontalAlignment: .leading) {
			topBarView()
		} selectedAction: { item in
			homeRouter.route(to: \.item, item)
		}
	}
}
