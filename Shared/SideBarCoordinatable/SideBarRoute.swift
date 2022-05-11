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

protocol Outputable {
	func using(coordinator: Any) -> ViewPresentable
	func sideBarItem(active: Bool, coordinator: Any) -> AnyView
}

public struct SideBarContent<T: SideBarCoordinatable, Output: ViewPresentable>: Outputable {
	func sideBarItem(active: Bool, coordinator: Any) -> AnyView {
		self.sideBarItem(coordinator as! T)(active)
	}

	func using(coordinator: Any) -> ViewPresentable {
		self.closure(coordinator as! T)()
	}

	let closure: (T) -> (() -> Output)
	let sideBarItem: (T) -> ((Bool) -> AnyView)

	init<sideBarItem: View>(closure: @escaping ((T) -> (() -> Output)),
	                        sideBarItem: @escaping ((T) -> ((Bool) -> sideBarItem)))
	{
		self.closure = closure
		self.sideBarItem = { coordinator in
			{
				AnyView(sideBarItem(coordinator)($0))
			}
		}
	}
}

@propertyWrapper
public class SideBarRoute<T: SideBarCoordinatable, Output: ViewPresentable> {
	public var wrappedValue: SideBarContent<T, Output>

	fileprivate init(standard: SideBarContent<T, Output>) {
		self.wrappedValue = standard
	}
}

public extension SideBarRoute where T: SideBarCoordinatable, Output == AnyView {
	convenience init<ViewOutput: View, sideBarItem: View>(wrappedValue: @escaping ((T) -> (() -> ViewOutput)),
	                                                      sideBarItem: @escaping ((T) -> ((Bool) -> sideBarItem)))
	{
		self.init(standard: SideBarContent(closure: { coordinator in { AnyView(wrappedValue(coordinator)()) }},
		                                   sideBarItem: sideBarItem))
	}
}

public extension SideBarRoute where T: SideBarCoordinatable, Output: Coordinatable {
	convenience init<sideBarItem: View>(wrappedValue: @escaping ((T) -> (() -> Output)),
	                                    sideBarItem: @escaping ((T) -> ((Bool) -> sideBarItem)))
	{
		self.init(standard: SideBarContent(closure: { coordinator in { wrappedValue(coordinator)() }},
		                                   sideBarItem: sideBarItem))
	}
}
