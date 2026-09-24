//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

/// `TabView` has an "overscroll" bug on some index selections, workaround with manual `UIPageViewController`
struct SupplementTabView<
    Element,
    ID: Hashable,
    Data: Collection,
    Content: View
>: PlatformViewControllerRepresentable where Data.Element == Element, Data.Index == Int {

    let data: Data
    let id: KeyPath<Element, ID>
    let selection: Binding<ID?>

    @ViewBuilder
    let content: (Element) -> Content

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
            data: data,
            newID: selection.wrappedValue,
            content: content
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            data: data,
            id: id,
            selection: selection
        )
    }

    final class Coordinator: NSObject, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

        weak var controller: UIPageViewController?

        private var requestedID: ID?
        private var selectionRevision = 0
        private var isTransitioning = false
        private var swipeSelection: (id: ID?, revision: Int)?
        private var data: Data
        private let id: KeyPath<Element, ID>
        private let selection: Binding<ID?>
        private var viewControllers: [ID: HostingController<Content>] = [:]

        init(
            data: Data,
            id: KeyPath<Element, ID>,
            selection: Binding<ID?>
        ) {
            self.data = data
            self.id = id
            self.selection = selection
        }

        func sync(
            data: Data,
            newID: ID?,
            @ViewBuilder content: (Element) -> Content
        ) {
            guard controller != nil else { return }

            let wasPresenting = requestedID != nil
            if requestedID != newID {
                selectionRevision += 1
            }
            requestedID = newID

            self.data = data

            updateHosts(with: data, content: content)

            selectCurrent(animated: wasPresenting)
        }

        private func selectCurrent(animated: Bool) {
            // UIKit must settle both programmatic and interactive transitions before
            // accepting another page. Read the binding again when a transition ends.
            guard !isTransitioning,
                  let controller,
                  let selection = selection.wrappedValue,
                  let targetID = targetID(for: selection),
                  let target = viewControllers[targetID]
            else { return }

            guard controller.viewControllers?.first !== target else { return }

            isTransitioning = true
            controller.setViewControllers(
                [target],
                direction: direction(from: controller.viewControllers?.first, to: targetID),
                animated: animated
            ) { [weak self] _ in
                guard let self else { return }
                isTransitioning = false
                selectCurrent(animated: true)
            }
        }

        private func updateHosts(
            with data: Data,
            @ViewBuilder content: (Element) -> Content
        ) {
            let currentIDs = Set(data.map { $0[keyPath: id] })
            viewControllers = viewControllers.filter { currentIDs.contains($0.key) }

            for element in data {
                if let host = viewControllers[element[keyPath: id]] {
                    host.content = content(element)
                } else {
                    let host = HostingController(content: content(element))
                    host.disableSafeArea = true
                    host.view.backgroundColor = .clear
                    viewControllers[element[keyPath: id]] = host
                }
            }
        }

        private func targetID(for selection: ID) -> ID? {
            let targetID = viewControllers[selection] != nil ? selection : data.first?[keyPath: id]

            if targetID != selection {
                let revision = selectionRevision
                DispatchQueue.main.async { [weak self] in
                    guard let self,
                          revision == selectionRevision,
                          self.selection.wrappedValue == selection,
                          viewControllers[selection] == nil,
                          data.first?[keyPath: id] == targetID
                    else { return }

                    self.selection.wrappedValue = targetID
                }
            }

            return targetID
        }

        private func direction(
            from visible: UIViewController?,
            to targetID: ID
        ) -> UIPageViewController.NavigationDirection {
            guard let visible,
                  let currentID = viewControllerID(for: visible),
                  let currentIndex = data.firstIndex(where: { $0[keyPath: id] == currentID }),
                  let targetIndex = data.firstIndex(where: { $0[keyPath: id] == targetID })
            else { return .forward }

            return targetIndex < currentIndex ? .reverse : .forward
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
            willTransitionTo pendingViewControllers: [UIViewController]
        ) {
            isTransitioning = true
            swipeSelection = (selection.wrappedValue, selectionRevision)
        }

        func pageViewController(
            _ controller: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted: Bool
        ) {
            guard let swipeSelection else { return }
            self.swipeSelection = nil
            isTransitioning = false

            // A tab tap or dismissal during the swipe takes precedence over its result.
            if transitionCompleted,
               swipeSelection.id != nil,
               swipeSelection.revision == selectionRevision,
               selection.wrappedValue == swipeSelection.id,
               let visible = controller.viewControllers?.first,
               let newID = viewControllerID(for: visible)
            {
                requestedID = newID
                selectionRevision += 1
                selection.wrappedValue = newID
            }

            selectCurrent(animated: true)
        }

        private func viewControllerID(for controller: UIViewController) -> ID? {
            viewControllers.first(where: { $0.value === controller })?.key
        }

        private func adjacent(to viewController: UIViewController, offset: Int) -> UIViewController? {
            guard let viewControllerID = viewControllerID(for: viewController),
                  let index = data.firstIndex(where: { $0[keyPath: id] == viewControllerID })
            else { return nil }

            let target = index + offset

            guard data.indices.contains(target) else { return nil }

            return viewControllers[data[target][keyPath: id]]
        }
    }
}
