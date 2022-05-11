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

struct SideBarChildItem {
	let presentable: ViewPresentable
	let keyPathIsEqual: (Any) -> Bool
	let sideBarItem: (Bool) -> AnyView
}

/// Wrapper around childCoordinators
/// Used so that you don't need to write @Published
public class SideBarChild: ObservableObject {
	weak var parent: ChildDismissable?
	public let startingItems: [AnyKeyPath]

	@Published
	var activeItem: SideBarChildItem!

	var allItems: [SideBarChildItem]!

	public var activeTab: Int? {
		didSet {
			guard oldValue != activeTab else { return }
			let newItem = allItems[activeTab ?? 0]
			self.activeItem = newItem
		}
	}

	public init(startingItems: [AnyKeyPath], activeTab: Int = 0) {
		self.startingItems = startingItems
		self.activeTab = activeTab
	}
}
