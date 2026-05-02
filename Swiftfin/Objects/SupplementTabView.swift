//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

// TODO: Remove when TabView is working as expected.

/// A `TabView` that does not scroll until the previous scroll completes
/// - Used to prevent the overscrolling caused by the regular `TabView` & programmatic tab selection
struct SupplementTabView<Item: Identifiable, Content: View>: UIViewControllerRepresentable {

    let items: [Item]
    @Binding
    var selection: Item.ID?
    @ViewBuilder
    let content: (Item) -> Content

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )

        controller.delegate = context.coordinator
        controller.dataSource = context.coordinator
        controller.view.backgroundColor = .clear

        context.coordinator.controller = controller

        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.sync(items: items, selection: selection)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

        var parent: SupplementTabView

        weak var controller: UIPageViewController?

        private var hosts: [Item.ID: UIHostingController<Content>] = [:]
        private var hasSetInitial = false

        init(parent: SupplementTabView) {
            self.parent = parent
        }

        func sync(items: [Item], selection: Item.ID?) {
            guard let controller else { return }

            let currentIDs = Set(items.map(\.id))
            hosts = hosts.filter { currentIDs.contains($0.key) }

            for item in items {
                if let host = hosts[item.id] {
                    host.rootView = parent.content(item)
                } else {
                    let host = UIHostingController(rootView: parent.content(item), ignoreSafeArea: true)
                    host.view.backgroundColor = .clear
                    hosts[item.id] = host
                }
            }

            let targetID = selection ?? items.first?.id

            guard let targetID, let target = hosts[targetID] else { return }

            let visible = controller.viewControllers?.first

            if visible === target {
                hasSetInitial = true
                return
            }

            let direction: UIPageViewController.NavigationDirection = {
                guard let visible,
                      let currentID = id(for: visible),
                      let currentIndex = items.firstIndex(where: { $0.id == currentID }),
                      let targetIndex = items.firstIndex(where: { $0.id == targetID })
                else { return .forward }

                return targetIndex < currentIndex ? .reverse : .forward
            }()

            controller.setViewControllers(
                [target],
                direction: direction,
                animated: hasSetInitial
            )

            hasSetInitial = true
        }

        // MARK: UIPageViewControllerDataSource

        func pageViewController(
            _ controller: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            adjacent(to: viewController, offset: -1)
        }

        func pageViewController(
            _ controller: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            adjacent(to: viewController, offset: 1)
        }

        // MARK: UIPageViewControllerDelegate

        func pageViewController(
            _ controller: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted: Bool
        ) {
            // Only commit the binding when the swipe actually settled.
            guard transitionCompleted,
                  let visible = controller.viewControllers?.first,
                  let newID = id(for: visible)
            else { return }

            if parent.selection != newID {
                DispatchQueue.main.async {
                    self.parent.selection = newID
                }
            }
        }

        private func id(for controller: UIViewController) -> Item.ID? {
            hosts.first(where: { $0.value === controller })?.key
        }

        private func adjacent(to viewController: UIViewController, offset: Int) -> UIViewController? {
            guard let id = id(for: viewController),
                  let index = parent.items.firstIndex(where: { $0.id == id })
            else { return nil }

            let target = index + offset

            guard parent.items.indices.contains(target) else { return nil }

            return hosts[parent.items[target].id]
        }
    }
}
