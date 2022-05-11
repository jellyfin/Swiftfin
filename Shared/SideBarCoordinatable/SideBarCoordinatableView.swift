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

struct SideBarCoordinatableView<T: SideBarCoordinatable, U: View>: View {
	private var coordinator: T
	private let router: SideBarRouter<T>
	@ObservedObject
	var child: SideBarChild
	private var customize: (AnyView) -> U
	private var views: [AnyView]

	var body: some View {
		customize(AnyView(NavigationView {
			List {
				ForEach(Array(views.enumerated()), id: \.offset) { view in
					//                            NavigationLink {
					//                                view.element
					//                            } label: {
					//                                coordinator.child.allItems[view.offset].sideBarItem(view.offset == child.activeTab)
					//                            }

					//                            let activeBinding = Binding<Bool>(get: { view.offset == child.activeTab },
					//                                                        set: { _ in })
//
					//                            NavigationLink(isActive: activeBinding) {
					//                                view.element
					//                            } label: {
					//                                coordinator.child.allItems[view.offset].sideBarItem(view.offset == child.activeTab)
					//                            }
					//                            .tag(view.offset)

					NavigationLink(tag: view.offset,
					               selection: $child.activeTab) {
						view.element
					} label: {
						coordinator.child.allItems[view.offset].sideBarItem(view.offset == child.activeTab)
					}
				}
			}
			.listStyle(SidebarListStyle())
			.navigationTitle("Swiftfin")

			if let firstView = views.first {
				firstView
			}
		}))
		.environmentObject(router)
	}

	init(paths: [AnyKeyPath], coordinator: T, customize: @escaping (AnyView) -> U) {
		self.coordinator = coordinator

		self.router = SideBarRouter(coordinator: coordinator.routerStorable)
		RouterStore.shared.store(router: router)
		self.customize = customize
		self.child = coordinator.child

		if coordinator.child.allItems == nil {
			coordinator.setupAllTabs()
		}

		self.views = coordinator.child.allItems.map {
			$0.presentable.view()
		}
	}
}
