//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

struct HomeView: View {

	@EnvironmentObject
	var homeRouter: HomeCoordinator.Router
	@StateObject
	var viewModel = HomeViewModel()
	@Default(.showPosterLabels)
	var showPosterLabels

	@State
	var showingSettings = false

	var body: some View {
		if viewModel.isLoading {
			ProgressView()
				.scaleEffect(2)
		} else {
			ScrollView {
				LazyVStack(alignment: .leading) {

					if viewModel.resumeItems.isEmpty {
						HomeCinematicView(viewModel: viewModel,
						                  items: viewModel.latestAddedItems.map { .init(item: $0, type: .plain) },
						                  forcedItemSubtitle: L10n.recentlyAdded)

						if !viewModel.nextUpItems.isEmpty {
							NextUpView(items: viewModel.nextUpItems)
								.focusSection()
						}
					} else {
						HomeCinematicView(viewModel: viewModel,
						                  items: viewModel.resumeItems.map { .init(item: $0, type: .resume) })

						if !viewModel.nextUpItems.isEmpty {
							NextUpView(items: viewModel.nextUpItems)
								.focusSection()
						}

						PortraitItemsRowView(rowTitle: L10n.recentlyAdded,
						                     items: viewModel.latestAddedItems,
						                     showItemTitles: showPosterLabels) { item in
							homeRouter.route(to: \.modalItem, item)
						}
					}

					ForEach(viewModel.libraries, id: \.self) { library in
						LatestMediaView(viewModel: LatestMediaViewModel(library: library))
							.focusSection()
					}

					Spacer(minLength: 100)

					HStack {
						Spacer()

						Button {
							viewModel.refresh()
						} label: {
							L10n.refresh.text
						}

						Spacer()
					}
					.focusSection()
				}
			}
			.edgesIgnoringSafeArea(.top)
			.edgesIgnoringSafeArea(.horizontal)
		}
	}
}
