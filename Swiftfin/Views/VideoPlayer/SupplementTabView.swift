//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import SwiftUI
import UIKit

/// `TabView` has an "overscroll" bug on some index selections, workaround with manual `UIPageViewController`
struct SupplementTabView<Item: Identifiable, Content: View>: UIViewControllerRepresentable {

    let items: [Item]
    let selection: Binding<Item.ID?>

    @ViewBuilder
    let content: (Item) -> Content

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )

        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        controller.view.backgroundColor = .clear

        context.coordinator.controller = controller

        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        context.coordinator.sync(
            items: items,
            newID: selection.wrappedValue,
            content: content
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: selection)
    }

    final class Coordinator: NSObject, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

        weak var controller: UIPageViewController?

        private var currentID: Item.ID?
        private var viewControllers: [Item.ID: HostingController<Content>] = [:]
        private var items: [Item] = []
        private let selection: Binding<Item.ID?>

        init(selection: Binding<Item.ID?>) {
            self.selection = selection
        }

        func sync(
            items: [Item],
            newID: Item.ID?,
            @ViewBuilder content: (Item) -> Content
        ) {
            guard let controller else { return }

            let previousID = currentID

            self.items = items

            updateHosts(with: items, content: content)

            switch (previousID, newID) {
            case (_, nil):
                currentID = nil

            case (nil, let .some(newID)):
                select(
                    targetID(for: newID),
                    in: controller,
                    animated: false
                )

            case let (.some, .some(selection)):
                select(
                    targetID(for: selection),
                    in: controller,
                    animated: true
                )
            }
        }

        private func select(
            _ targetID: Item.ID?,
            in controller: UIPageViewController,
            animated: Bool
        ) {
            guard let targetID, let target = viewControllers[targetID] else { return }

            currentID = targetID

            guard controller.viewControllers?.first !== target else { return }

            controller.setViewControllers(
                [target],
                direction: direction(from: controller.viewControllers?.first, to: targetID),
                animated: animated
            )
        }

        private func updateHosts(
            with items: [Item],
            @ViewBuilder content: (Item) -> Content
        ) {
            let currentIDs = Set(items.map(\.id))
            viewControllers = viewControllers.filter { currentIDs.contains($0.key) }

            for item in items {
                if let host = viewControllers[item.id] {
                    host.content = content(item)
                } else {
                    let host = HostingController(content: content(item))
                    host.disableSafeArea = true
                    host.view.backgroundColor = .clear
                    viewControllers[item.id] = host
                }
            }
        }

        private func targetID(for selection: Item.ID) -> Item.ID? {
            let targetID = viewControllers[selection] != nil ? selection : items.first?.id

            if targetID != selection {
                setSelection(targetID)
            }

            return targetID
        }

        private func direction(
            from visible: UIViewController?,
            to targetID: Item.ID
        ) -> UIPageViewController.NavigationDirection {
            guard let visible,
                  let currentID = id(for: visible),
                  let currentIndex = items.firstIndex(where: { $0.id == currentID }),
                  let targetIndex = items.firstIndex(where: { $0.id == targetID })
            else { return .forward }

            return targetIndex < currentIndex ? .reverse : .forward
        }

        private func setSelection(_ id: Item.ID?) {
            DispatchQueue.main.async {
                self.selection.wrappedValue = id
            }
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

            if selection.wrappedValue != newID {
                setSelection(newID)
            }
        }

        private func id(for controller: UIViewController) -> Item.ID? {
            viewControllers.first(where: { $0.value === controller })?.key
        }

        private func adjacent(to viewController: UIViewController, offset: Int) -> UIViewController? {
            guard let id = id(for: viewController),
                  let index = items.firstIndex(where: { $0.id == id })
            else { return nil }

            let target = index + offset

            guard items.indices.contains(target) else { return nil }

            return viewControllers[items[target].id]
        }
    }
}
