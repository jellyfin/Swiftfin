//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI
import UIKit

// TODO: Generalize this view such that it can be used in other contexts like for a library

struct HomeCinematicViewItem: Hashable {

	enum TopRowType {
		case resume
		case nextUp
		case plain
	}

	let item: BaseItemDto
	let type: TopRowType

	func hash(into hasher: inout Hasher) {
		hasher.combine(item)
		hasher.combine(type)
	}
}

struct HomeCinematicView: View {

	@FocusState
	var selectedItem: BaseItemDto?
	@ObservedObject
	var viewModel: HomeViewModel
	@State
	private var updatedSelectedItem: BaseItemDto?
	@State
	private var initiallyAppeared = false
	private let forcedItemSubtitle: String?
	private let items: [HomeCinematicViewItem]
	private let backgroundViewModel = DynamicCinematicBackgroundViewModel()

	init(viewModel: HomeViewModel, items: [HomeCinematicViewItem], forcedItemSubtitle: String? = nil) {
		self.viewModel = viewModel
		self.items = items
		self.forcedItemSubtitle = forcedItemSubtitle
	}

	var body: some View {

		ZStack(alignment: .bottom) {

			CinematicBackgroundView(viewModel: backgroundViewModel)
				.frame(height: UIScreen.main.bounds.height - 10)

			LinearGradient(stops: [
				.init(color: .clear, location: 0.5),
				.init(color: .black.opacity(0.6), location: 0.7),
				.init(color: .black, location: 1),
			],
			startPoint: .top,
			endPoint: .bottom)
				.ignoresSafeArea()

			VStack(alignment: .leading, spacing: 0) {

				VStack(alignment: .leading, spacing: 0) {

					if let forcedItemSubtitle = forcedItemSubtitle {
						Text(forcedItemSubtitle)
							.font(.callout)
							.fontWeight(.medium)
							.foregroundColor(Color.secondary)
					} else {
						if updatedSelectedItem?.itemType == .episode {
							Text(updatedSelectedItem?.getEpisodeLocator() ?? "")
								.font(.callout)
								.fontWeight(.medium)
								.foregroundColor(Color.secondary)
						} else {
							Text("")
						}
					}

					Text("\(updatedSelectedItem?.seriesName ?? updatedSelectedItem?.name ?? "")")
						.font(.title)
						.fontWeight(.semibold)
						.foregroundColor(.primary)
						.lineLimit(1)
						.fixedSize(horizontal: false, vertical: true)
				}
				.padding(.horizontal, 50)

				ScrollView(.horizontal, showsIndicators: false) {
					HStack {
						ForEach(items, id: \.self) { item in
							switch item.type {
							case .nextUp:
								CinematicNextUpCardView(item: item.item, showOverlay: true)
									.focused($selectedItem, equals: item.item)
							case .resume:
								CinematicResumeCardView(viewModel: viewModel, item: item.item)
									.focused($selectedItem, equals: item.item)
							case .plain:
								CinematicNextUpCardView(item: item.item, showOverlay: false)
									.focused($selectedItem, equals: item.item)
							}
						}
					}
					.padding(.horizontal, 50)
					.padding(.bottom)
				}
				.focusSection()
			}
		}
		.onChange(of: selectedItem) { newValue in
			if let newItem = newValue {
				backgroundViewModel.select(item: newItem)
				updatedSelectedItem = newItem
			}
		}
		.onAppear {
			guard !initiallyAppeared else { return }
			selectedItem = items.first?.item
			updatedSelectedItem = items.first?.item
			initiallyAppeared = true
		}
	}
}
