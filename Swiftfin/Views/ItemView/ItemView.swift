//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Introspect
import JellyfinAPI
import SwiftUI

// Intermediary view for ItemView to set navigation bar settings
struct ItemNavigationView: View {
	private let item: BaseItemDto

	init(item: BaseItemDto) {
		self.item = item
	}

	var body: some View {
		ItemView(item: item)
			.navigationBarTitle(item.name ?? "", displayMode: .inline)
	}
}

private struct ItemView: View {
	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router

	@State
	private var orientation: UIDeviceOrientation = .unknown
	@Environment(\.horizontalSizeClass)
	private var hSizeClass
	@Environment(\.verticalSizeClass)
	private var vSizeClass
    
    let item: BaseItemDto

	var body: some View {
		Group {
            switch item.itemType {
            case .episode:
                EpisodeItemView()
                    .environmentObject(EpisodeItemViewModel(item: item))
            case .series:
                if UIDevice.isIPad {
                    iPadOSSeriesItemView()
                        .environmentObject(SeriesItemViewModel(item: item))
                } else {
                    SeriesItemView()
                        .environmentObject(SeriesItemViewModel(item: item))
                }
            default:
                ItemPortraitMainView()
                    .environmentObject(ItemViewModel(item: item))
            }
		}
	}
}
