//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemOverviewView: View {

	@EnvironmentObject
	var itemOverviewRouter: ItemOverviewCoordinator.Router
	let item: BaseItemDto

	var body: some View {
		ScrollView(showsIndicators: false) {
			Text(item.overview ?? "")
				.font(.footnote)
				.padding()
		}
        .navigationBarTitle(L10n.overview, displayMode: .inline)
		.toolbar {
			ToolbarItemGroup(placement: .navigationBarLeading) {
				Button {
					itemOverviewRouter.dismissCoordinator()
				} label: {
					Image(systemName: "xmark.circle.fill")
				}
			}
		}
	}
}
