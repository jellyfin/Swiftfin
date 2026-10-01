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
struct SupplementTabView<Content: View>: PlatformViewControllerRepresentable {

    let data: [any MediaPlayerSupplement]
    let selection: Binding<String?>

    @ViewBuilder
    let content: (any MediaPlayerSupplement) -> Content

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        context.coordinator.container = controller
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        context.coordinator.sync(data: data, selection: selection, content: content)
    }

    static func dismantleUIViewController(_: UIViewController, coordinator: Coordinator) {
        coordinator.removeAll()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: selection)
    }

    final class Coordinator: NSObject, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

        weak var container: UIViewController?

        private var hosts: [String: HostingController<Content>] = [:]
        private var ids: [String] = []
        private var pageController: UIPageViewController?
        private var requestedID: String?
        private var selectionRevision = 0
        private var swipeSelection: (id: String?, revision: Int)?
        private var selection: Binding<String?>

        init(selection: Binding<String?>) {
            self.selection = selection
        }

        func sync(
            data: [any MediaPlayerSupplement],
            selection: Binding<String?>,
            @ViewBuilder content: (any MediaPlayerSupplement) -> Content
        ) {
            guard container != nil else { return }

            self.selection = selection
            let newIDs = data.map(\.id)
            let trackChanged = ids != newIDs
            if trackChanged {
                selectionRevision += 1
                // Clear UIKit's adjacent-page cache before releasing hosts that left the track.
                removePageController()
            }
            ids = newIDs
            hosts = hosts.filter { newIDs.contains($0.key) }
            for supplement in data {
                if let host = hosts[supplement.id] {
                    host.content = content(supplement)
                } else {
                    let host = HostingController(content: content(supplement))
                    host.disableSafeArea = true
                    host.view.backgroundColor = .clear
                    hosts[supplement.id] = host
                }
            }

            selectCurrent()
        }

        func removeAll() {
            selectionRevision += 1
            removePageController()
            hosts.removeAll()
            ids.removeAll()
            requestedID = nil
            selection = .constant(nil)
        }

        private func makePageController() -> UIPageViewController? {
            guard let container else { return nil }
            if let pageController {
                return pageController
            }

            let page = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
            page.dataSource = self
            page.delegate = self
            page.view.backgroundColor = .clear
            page.view.translatesAutoresizingMaskIntoConstraints = false
            container.addChild(page)
            container.view.addSubview(page.view)
            NSLayoutConstraint.activate([
                page.view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
                page.view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
                page.view.topAnchor.constraint(equalTo: container.view.topAnchor),
                page.view.bottomAnchor.constraint(equalTo: container.view.bottomAnchor),
            ])
            page.didMove(toParent: container)
            pageController = page
            return page
        }

        private func removePageController() {
            guard let page = pageController else { return }
            pageController = nil
            page.delegate = nil
            page.dataSource = nil
            remove(page)
            for host in hosts.values {
                remove(host)
            }
            swipeSelection = nil
        }

        private func remove(_ controller: UIViewController) {
            guard controller.parent != nil else { return }
            controller.view.layer.removeAllAnimations()
            controller.willMove(toParent: nil)
            controller.view.removeFromSuperview()
            controller.removeFromParent()
        }

        private func selectCurrent() {
            let newID = selection.wrappedValue
            if requestedID != newID {
                selectionRevision += 1
                requestedID = newID

                // A tab tap takes precedence over an in-flight swipe. Rebuild the
                // pager so its eventual completion cannot restore the old panel.
                if swipeSelection != nil {
                    removePageController()
                }
            }

            guard let targetID = requestedID, let target = hosts[targetID] else {
                removePageController()
                return
            }

            guard swipeSelection == nil,
                  let page = makePageController()
            else { return }

            guard page.viewControllers?.first !== target else { return }

            let direction = direction(from: page.viewControllers?.first, to: targetID)
            // The container can change height at the same time (regular/expanded
            // supplements). Animating UIKit's page scroll during that resize can
            // leave its visible page behind the selection. Only user swipes page
            // interactively; explicit selections are installed synchronously.
            page.setViewControllers(
                [target],
                direction: direction,
                animated: false
            )
        }

        private func direction(
            from visible: UIViewController?,
            to targetID: String
        ) -> UIPageViewController.NavigationDirection {
            guard let visible,
                  let currentID = hostID(for: visible),
                  let currentIndex = ids.firstIndex(of: currentID),
                  let targetIndex = ids.firstIndex(of: targetID)
            else { return .forward }
            return targetIndex < currentIndex ? .reverse : .forward
        }

        // MARK: UIPageViewControllerDataSource

        func pageViewController(
            _ controller: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard controller === pageController else { return nil }
            return adjacent(to: viewController, offset: -1)
        }

        func pageViewController(
            _ controller: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard controller === pageController else { return nil }
            return adjacent(to: viewController, offset: 1)
        }

        // MARK: UIPageViewControllerDelegate

        func pageViewController(
            _ controller: UIPageViewController,
            willTransitionTo pendingViewControllers: [UIViewController]
        ) {
            guard controller === pageController else { return }
            swipeSelection = (selection.wrappedValue, selectionRevision)
        }

        func pageViewController(
            _ controller: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted: Bool
        ) {
            guard controller === pageController, let swipeSelection else { return }
            self.swipeSelection = nil

            // A tab tap or dismissal during the swipe takes precedence over its result.
            if transitionCompleted,
               swipeSelection.id != nil,
               swipeSelection.revision == selectionRevision,
               selection.wrappedValue == swipeSelection.id,
               let visible = controller.viewControllers?.first,
               let newID = hostID(for: visible)
            {
                requestedID = newID
                selectionRevision += 1
                selection.wrappedValue = newID
            }
            // UIKit still owns the page hierarchy while delivering this callback.
            DispatchQueue.main.async { [weak self, weak controller] in
                guard let self, let controller, self.pageController === controller else { return }
                self.selectCurrent()
            }
        }

        private func hostID(for controller: UIViewController) -> String? {
            hosts.first { $0.value === controller }?.key
        }

        private func adjacent(to viewController: UIViewController, offset: Int) -> UIViewController? {
            guard let id = hostID(for: viewController),
                  let index = ids.firstIndex(of: id)
            else { return nil }
            let target = index + offset
            guard ids.indices.contains(target) else { return nil }
            return hosts[ids[target]]
        }
    }
}
