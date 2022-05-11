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

/// The TabCoordinatable is used to represent a coordinator with a TabView
public protocol SideBarCoordinatable: Coordinatable {
	typealias Route = SideBarRoute
	typealias Router = SideBarRouter<Self>
	associatedtype RouterStoreType

	var routerStorable: RouterStoreType { get }

	var child: SideBarChild { get }

	associatedtype CustomizeViewType: View

	/**
	 Implement this function if you wish to customize the view on all views and child coordinators, for instance, if you wish to change the `tintColor` or inject an `EnvironmentObject`.

	 - Parameter view: The input view.

	 - Returns: The modified view.
	 */
	func customize(_ view: AnyView) -> CustomizeViewType

	/**
	 Searches the tabbar for the first route that matches the route and makes it the active tab.

	 - Parameter route: The route that will be focused.
	 */
	@discardableResult
	func focusFirst<Output: Coordinatable>(_ route: KeyPath<Self, SideBarContent<Self, Output>>) -> Output

	/**
	 Searches the tabbar for the first route that matches the route and makes it the active tab.

	 - Parameter route: The route that will be focused.
	 */
	@discardableResult
	func focusFirst<Output: View>(_ route: KeyPath<Self, SideBarContent<Self, Output>>) -> Self
}

public extension SideBarCoordinatable {
	var routerStorable: Self {
		self
	}

	func dismissChild<T: Coordinatable>(coordinator: T, action: (() -> Void)?) {
		fatalError("Not implemented")
	}

	var parent: ChildDismissable? {
		get {
			child.parent
		} set {
			child.parent = newValue
		}
	}

	internal func setupAllTabs() {
		var all: [SideBarChildItem] = []

		for abs in self.child.startingItems {
			let ina = self[keyPath: abs]

			if let val = ina as? Outputable {
				all.append(SideBarChildItem(presentable: val.using(coordinator: self),
				                            keyPathIsEqual: {
				                            	let lhs = abs as! PartialKeyPath<Self>
				                            	let rhs = $0 as! PartialKeyPath<Self>
				                            	return (lhs == rhs)
				                            },
				                            sideBarItem: { [unowned self] in
				                            	val.sideBarItem(active: $0, coordinator: self)
				                            }))
			}
		}

		self.child.allItems = all
	}

	func customize(_ view: AnyView) -> some View {
		view
	}

	func view() -> AnyView {
		AnyView(SideBarCoordinatableView(paths: self.child.startingItems,
		                                 coordinator: self,
		                                 customize: customize))
	}

	@discardableResult
	func focusFirst<Output: Coordinatable>(_ route: KeyPath<Self, SideBarContent<Self, Output>>) -> Output {
		if child.allItems == nil {
			setupAllTabs()
		}

		guard let value = child.allItems.enumerated().first(where: { item in
			guard item.element.keyPathIsEqual(route) else {
				return false
			}

			return true
		}) else {
			fatalError()
		}

		self.child.activeTab = value.offset

		return value.element.presentable as! Output
	}

	@discardableResult
	func focusFirst<Output: View>(_ route: KeyPath<Self, SideBarContent<Self, Output>>) -> Self {
		if child.allItems == nil {
			setupAllTabs()
		}

		guard let value = child.allItems.enumerated().first(where: { item in
			guard item.element.keyPathIsEqual(route) else {
				return false
			}

			return true
		}) else {
			fatalError()
		}

		self.child.activeTab = value.offset

		return self
	}
}
