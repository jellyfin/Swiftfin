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

/// `TabView` acts weird with horizontal stacks, so tvOS swaps tracked child hosts directly.
struct SupplementTabView<Item: Identifiable, Content: View>: UIViewControllerRepresentable {

    let items: [Item]
    let selection: Item.ID?

    @ViewBuilder
    let content: (Item) -> Content

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear

        context.coordinator.container = controller

        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        context.coordinator.container = controller
        context.coordinator.sync(
            items: items,
            selection: selection,
            content: content
        )
    }

    static func dismantleUIViewController(_: UIViewController, coordinator: Coordinator) {
        coordinator.removeAll()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {

        weak var container: UIViewController?

        private var visibleID: Item.ID?
        private var transitionID: Int = 0
        private var hosts: [Item.ID: HostingController<Content>] = [:]

        func sync(
            items: [Item],
            selection: Item.ID?,
            @ViewBuilder content: (Item) -> Content
        ) {
            guard let container else { return }

            updateHosts(with: items, content: content)
            select(selection, in: container)
        }

        func removeAll() {
            for host in hosts.values {
                remove(host)
            }

            hosts.removeAll()
            visibleID = nil
        }

        private func updateHosts(
            with items: [Item],
            @ViewBuilder content: (Item) -> Content
        ) {
            let currentIDs = Set(items.map(\.id))

            let removedIDs = hosts.keys.filter { !currentIDs.contains($0) }

            for id in removedIDs {
                guard let host = hosts[id] else { continue }

                remove(host)
                hosts[id] = nil

                if visibleID == id {
                    visibleID = nil
                }
            }

            for item in items {
                if let host = hosts[item.id] {
                    host.rootView = content(item)
                } else {
                    let host = HostingController(content: content(item))
                    host.disablesSafeArea = true
                    host.view.backgroundColor = .clear
                    hosts[item.id] = host
                }
            }
        }

        private func select(_ selection: Item.ID?, in container: UIViewController) {
            guard let selection else {
                removeVisibleHost(animated: true)
                return
            }

            guard let host = hosts[selection] else {
                removeVisibleHost(animated: true)
                return
            }

            if host.parent === container {
                visibleID = selection
                host.view.alpha = 1
                return
            }

            let previousHost = visibleID.flatMap { hosts[$0] }

            remove(host)
            add(host, to: container, alpha: 0)
            visibleID = selection
            transition(from: previousHost, to: host)
        }

        private func add(_ host: UIViewController, to container: UIViewController, alpha: CGFloat = 1) {
            container.addChild(host)
            container.view.addSubview(host.view)

            host.view.frame = container.view.bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            host.view.alpha = alpha

            host.didMove(toParent: container)
        }

        private func removeVisibleHost(animated: Bool = false) {
            guard let visibleID, let host = hosts[visibleID] else {
                self.visibleID = nil
                return
            }

            self.visibleID = nil

            guard animated else {
                remove(host)
                return
            }

            transition(from: host, to: nil)
        }

        private func transition(from oldHost: UIViewController?, to newHost: UIViewController?) {
            transitionID += 1
            let currentTransitionID = transitionID

            UIView.animate(
                withDuration: 0.18,
                delay: 0,
                options: [.beginFromCurrentState, .allowUserInteraction]
            ) {
                oldHost?.view.alpha = 0
                newHost?.view.alpha = 1
            } completion: { [weak self, weak oldHost, weak newHost] _ in
                guard let self, currentTransitionID == self.transitionID else { return }

                if let oldHost, oldHost !== newHost {
                    self.remove(oldHost)
                }
            }
        }

        private func remove(_ host: UIViewController) {
            guard host.parent != nil else { return }

            host.willMove(toParent: nil)
            host.view.removeFromSuperview()
            host.removeFromParent()
        }
    }
}
