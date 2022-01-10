//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import Introspect
import SwiftUI

struct HomeView: View {

	@EnvironmentObject
	var homeRouter: HomeCoordinator.Router
	@StateObject
	var viewModel = HomeViewModel()

	private let refreshHelper = RefreshHelper()

	@ViewBuilder
	var innerBody: some View {
		if let errorMessage = viewModel.errorMessage {
			VStack(spacing: 5) {
				if viewModel.isLoading {
					ProgressView()
						.frame(width: 100, height: 100)
						.scaleEffect(2)
				} else {
					Image(systemName: "xmark.circle.fill")
						.font(.system(size: 72))
						.foregroundColor(Color.red)
						.frame(width: 100, height: 100)
				}

				Text("\(errorMessage.code)")
				Text(errorMessage.displayMessage)
					.frame(minWidth: 50, maxWidth: 240)
					.multilineTextAlignment(.center)

                PrimaryButtonView(title: L10n.retry) {
					viewModel.refresh()
				}
			}
			.offset(y: -50)
		} else if viewModel.isLoading {
			ProgressView()
				.frame(width: 100, height: 100)
				.scaleEffect(2)
		} else {
			ScrollView {
				VStack(alignment: .leading) {
					if !viewModel.resumeItems.isEmpty {
						ContinueWatchingView(viewModel: viewModel)
					}

					if !viewModel.nextUpItems.isEmpty {
						PortraitImageHStackView(items: viewModel.nextUpItems,
						                        horizontalAlignment: .leading) {
							L10n.nextUp.text
								.font(.title2)
								.fontWeight(.bold)
								.padding()
						} selectedAction: { item in
							homeRouter.route(to: \.item, item)
						}
					}

					if !viewModel.latestAddedItems.isEmpty {
						PortraitImageHStackView(items: viewModel.latestAddedItems) {
                            L10n.recentlyAdded.text
								.font(.title2)
								.fontWeight(.bold)
								.padding()
						} selectedAction: { item in
							homeRouter.route(to: \.item, item)
						}
					}

					ForEach(viewModel.libraries, id: \.self) { library in

						LatestMediaView(viewModel: LatestMediaViewModel(library: library)) {
							HStack {
								Text(L10n.latestWithString(library.name ?? ""))
									.font(.title2)
									.fontWeight(.bold)

								Spacer()

								Button {
									homeRouter
										.route(to: \.library, (viewModel: .init(parentID: library.id!,
										                                        filters: viewModel.recentFilterSet),
										                       title: library.name ?? ""))
								} label: {
									HStack {
										L10n.seeAll.text.font(.subheadline).fontWeight(.bold)
										Image(systemName: "chevron.right").font(Font.subheadline.bold())
									}
								}
							}
							.padding()
						}
					}
				}
				.padding(.bottom, 50)
			}
			.introspectScrollView { scrollView in
				let control = UIRefreshControl()

				refreshHelper.refreshControl = control
				refreshHelper.refreshAction = viewModel.refresh

				control.addTarget(refreshHelper, action: #selector(RefreshHelper.didRefresh), for: .valueChanged)
				scrollView.refreshControl = control
			}
		}
	}

	var body: some View {
		innerBody
			.navigationTitle(L10n.home)
			.toolbar {
				ToolbarItemGroup(placement: .navigationBarTrailing) {
					Button {
						homeRouter.route(to: \.settings)
					} label: {
						Image(systemName: "gearshape.fill")
					}
				}
			}
			.onAppear {
				refreshHelper.refreshStaleData()
			}
	}
}
