//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import Stinsen
import SwiftUI

struct LibraryListView: View {
	@EnvironmentObject
	var libraryListRouter: LibraryListCoordinator.Router
	@StateObject
	var viewModel = LibraryListViewModel()

	@Default(.Experimental.liveTVAlphaEnabled)
	var liveTVAlphaEnabled

	var supportedCollectionTypes: [String] {
		if liveTVAlphaEnabled {
			return ["movies", "tvshows", "livetv", "boxsets", "other"]
		} else {
			return ["movies", "tvshows", "boxsets", "other"]
		}
	}

	var body: some View {
		ScrollView {
			LazyVStack {
				Button {
					libraryListRouter.route(to: \.library,
					                        (viewModel: LibraryViewModel(filters: viewModel.withFavorites), title: L10n.favorites))
				} label: {
					ZStack {
						HStack {
							Spacer()
							L10n.yourFavorites.text
								.foregroundColor(.black)
								.font(.subheadline)
								.fontWeight(.semibold)
							Spacer()
						}
					}
					.padding(16)
					.background(Color.white)
					.frame(minWidth: 100, maxWidth: .infinity)
				}
				.cornerRadius(10)
				.shadow(radius: 5)
				.padding(.bottom, 5)

				if !viewModel.isLoading {
					ForEach(viewModel.libraries.filter { [self] library in
						let collectionType = library.collectionType ?? "other"
						return self.supportedCollectionTypes.contains(collectionType)
					}, id: \.id) { library in
						Button {
							if library.collectionType == "livetv" {
								libraryListRouter.route(to: \.liveTV)
							} else {
								libraryListRouter.route(to: \.library,
								                        (viewModel: LibraryViewModel(parentID: library.id),
								                         title: library.name ?? ""))
							}
						} label: {
							ZStack {
								ImageView(library.getPrimaryImage(maxWidth: 500), blurHash: library.getPrimaryImageBlurHash())
									.opacity(0.4)
									.accessibilityIgnoresInvertColors()
								HStack {
									Spacer()
									VStack {
										Text(library.name ?? "")
											.foregroundColor(.white)
											.font(.title2)
											.fontWeight(.semibold)
									}
									Spacer()
								}.padding(32)
							}.background(Color.black)
								.frame(minWidth: 100, maxWidth: .infinity)
								.frame(height: 100)
						}
						.cornerRadius(10)
						.shadow(radius: 5)
						.padding(.bottom, 5)
					}
				} else {
					ProgressView()
				}
			}.padding(.leading, 16)
				.padding(.trailing, 16)
				.padding(.top, 8)
		}
		.navigationTitle(L10n.allMedia)
		.toolbar {
			ToolbarItemGroup(placement: .navigationBarTrailing) {
				Button {
					libraryListRouter.route(to: \.search, LibrarySearchViewModel(parentID: nil))
				} label: {
					Image(systemName: "magnifyingglass")
				}
			}
		}
	}
}
