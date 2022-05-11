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

public class SideBarRouter<T>: Routable {
	public var coordinator: T {
		_coordinator.value as! T
	}

	private var _coordinator: WeakRef<AnyObject>

	public init(coordinator: T) {
		self._coordinator = WeakRef(value: coordinator as AnyObject)
	}
}

public extension SideBarRouter where T: SideBarCoordinatable {
	/**
	 Searches the tabbar for the first route that matches the route and makes it the active tab.

	 - Parameter route: The route that will be focused.
	 */
	@discardableResult
	func focusFirst<Output: Coordinatable>(_ route: KeyPath<T, SideBarContent<T, Output>>) -> Output {
		self.coordinator.focusFirst(route)
	}

	/**
	 Searches the tabbar for the first route that matches the route and makes it the active tab.

	 - Parameter route: The route that will be focused.
	 */
	@discardableResult
	func focusFirst<Output: View>(_ route: KeyPath<T, SideBarContent<T, Output>>) -> T {
		self.coordinator.focusFirst(route)
	}
}
