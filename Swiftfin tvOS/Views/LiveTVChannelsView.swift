//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI
import SwiftUICollection

struct LiveTVChannelsView: View {
	@EnvironmentObject
	var router: LiveTVChannelsCoordinator.Router
	@StateObject
	var viewModel = LiveTVChannelsViewModel()

	var body: some View {
		if viewModel.isLoading == true {
			ProgressView()
		} else if !viewModel.rows.isEmpty {
			CollectionView(rows: viewModel.rows) { _, _ in
				createGridLayout()
			} cell: { indexPath, cell in
				makeCellView(indexPath: indexPath, cell: cell)
			} supplementaryView: { _, indexPath in
				EmptyView()
					.accessibilityIdentifier("\(indexPath.section).\(indexPath.row)")
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.ignoresSafeArea()
			.onAppear {
				viewModel.startScheduleCheckTimer()
			}
			.onDisappear {
				viewModel.stopScheduleCheckTimer()
			}
		} else {
			VStack {
				Text("No results.")
				Button {
					viewModel.getChannels()
				} label: {
					Text("Reload")
				}
			}
		}
	}

	@ViewBuilder
	func makeCellView(indexPath: IndexPath, cell: LiveTVChannelRowCell) -> some View {
		let item = cell.item
		let channel = item.channel
		if channel.type != "Folder" {
			Button {
                self.viewModel.fetchVideoPlayerViewModel(item: channel) { playerViewModel in
                    self.router.route(to: \.videoPlayer, playerViewModel)
                }
			} label: {
				LiveTVChannelItemElement(channel: channel,
				                         program: item.program,
				                         startString: item.program?.getLiveStartTimeString(formatter: viewModel.timeFormatter) ?? " ",
				                         endString: item.program?.getLiveEndTimeString(formatter: viewModel.timeFormatter) ?? " ",
				                         progressPercent: item.program?.getLiveProgressPercentage() ?? 0)
			}
			.buttonStyle(PlainNavigationLinkButtonStyle())
		}
	}

	private func createGridLayout() -> NSCollectionLayoutSection {
		// I don't know why tvOS has a margin on the sides of a collection view
		// But it does, even with contentInset = .zero and ignoreSafeArea.
		let sideMargin = CGFloat(30)
		let itemWidth = (UIScreen.main.bounds.width / 4) - (sideMargin * 2)
		let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth),
		                                      heightDimension: .absolute(itemWidth))
		let item = NSCollectionLayoutItem(layoutSize: itemSize)
		item.edgeSpacing = .init(leading: .fixed(8),
		                         top: .fixed(8),
		                         trailing: .fixed(8),
		                         bottom: .fixed(8))

		let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
		                                       heightDimension: .absolute(itemWidth))
		let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
		                                               subitems: [item])
		group.edgeSpacing = .init(leading: .fixed(0),
		                          top: .fixed(16),
		                          trailing: .fixed(0),
		                          bottom: .fixed(16))
		group.contentInsets = .zero

		let section = NSCollectionLayoutSection(group: group)
		section.contentInsets = .zero

		return section
	}
}
