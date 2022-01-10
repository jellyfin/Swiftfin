//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import Stinsen
import SwiftUI

struct LibraryListView: View {
	@EnvironmentObject
	var libraryListRouter: LibraryListCoordinator.Router
	@StateObject
	var viewModel = LibraryListViewModel()

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

					if let collectionsLibraryItem = viewModel.libraries.first(where: { $0.collectionType == "boxsets" }) {
						Button {
							libraryListRouter.route(to: \.library,
							                        (viewModel: LibraryViewModel(parentID: collectionsLibraryItem.id),
							                         title: collectionsLibraryItem.name ?? ""))
						} label: {
							ZStack {
								ImageView(src: collectionsLibraryItem.getPrimaryImage(maxWidth: 500),
								          bh: collectionsLibraryItem.getPrimaryImageBlurHash())
									.opacity(0.4)
								HStack {
									Spacer()
									VStack {
										Text(collectionsLibraryItem.name ?? "")
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

					ForEach(viewModel.libraries, id: \.id) { library in
						if library.collectionType ?? "" == "movies" || library.collectionType ?? "" == "tvshows" {
							Button {
								libraryListRouter.route(to: \.library,
								                        (viewModel: LibraryViewModel(parentID: library.id),
								                         title: library.name ?? ""))
							} label: {
								ZStack {
									ImageView(src: library.getPrimaryImage(maxWidth: 500), bh: library.getPrimaryImageBlurHash())
										.opacity(0.4)
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
						} else {
							EmptyView()
						}
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
