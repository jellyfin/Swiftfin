//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import SwiftUI

struct LibraryListView: View {
	@EnvironmentObject
	var mainCoordinator: MainCoordinator.Router
	@EnvironmentObject
	var libraryListRouter: LibraryListCoordinator.Router
	@StateObject
	var viewModel = LibraryListViewModel()

	@Default(.Experimental.liveTVAlphaEnabled)
	var liveTVAlphaEnabled

	let supportedCollectionTypes = ["movies", "tvshows", "boxsets", "livetv", "other"]

	var body: some View {
		ScrollView {
			LazyVStack {
				if !viewModel.isLoading {

					ForEach(viewModel.libraries.filter { [self] library in
						let collectionType = library.collectionType ?? "other"
						return self.supportedCollectionTypes.contains(collectionType)
					}, id: \.id) { library in
						if library.collectionType == "livetv" {
							if liveTVAlphaEnabled {
								Button {
									self.mainCoordinator.root(\.liveTV)
								}
									label: {
										ZStack {
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
										}
										.frame(minWidth: 100, maxWidth: .infinity)
										.frame(height: 100)
									}
										.cornerRadius(10)
										.shadow(radius: 5)
										.padding(.bottom, 5)
							}
						} else {
							Button {
								self.libraryListRouter.route(to: \.library,
								                             (viewModel: LibraryViewModel(parentID: library.id), title: library.name ?? ""))
							}
								label: {
									ZStack {
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
									}
									.frame(minWidth: 100, maxWidth: .infinity)
									.frame(height: 100)
								}
									.cornerRadius(10)
									.shadow(radius: 5)
									.padding(.bottom, 5)
						}
					}
				} else {
					ProgressView()
				}
			}.padding(.leading, 16)
				.padding(.trailing, 16)
				.padding(.top, 8)
		}
	}
}
