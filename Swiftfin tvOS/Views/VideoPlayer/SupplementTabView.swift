//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

/// `TabView` acts weird with horizontal stacks, workaround with manual supplement presentation
struct SupplementTabView<
    Element,
    ID: Hashable,
    Data: Collection,
    Content: View
>: PlatformViewControllerRepresentable where Data.Element == Element {

    let data: Data
    let id: KeyPath<Element, ID>
    let selection: Binding<ID?>

    @ViewBuilder
    let content: (Element) -> Content

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear

        context.coordinator.container = controller

        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        context.coordinator.container = controller
        context.coordinator.sync(
            data: data,
            selection: selection.wrappedValue,
            content: content
        )
    }

    static func dismantleUIViewController(_: UIViewController, coordinator: Coordinator) {
        coordinator.removeAll()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(id: id)
    }

    final class Coordinator {

        weak var container: UIViewController?

        private let id: KeyPath<Element, ID>
        private var visibleID: ID?
        private var transitionID: Int = 0
        private var hosts: [ID: HostingController<Content>] = [:]

        init(id: KeyPath<Element, ID>) {
            self.id = id
        }

        func sync(
            data: Data,
            selection: ID?,
            @ViewBuilder content: (Element) -> Content
        ) {
            guard let container else { return }

            updateHosts(with: data, content: content)
            select(selection, in: container)
        }

        func removeAll() {
            transitionID += 1

            for host in hosts.values {
                remove(host)
            }

            hosts.removeAll()
            visibleID = nil
        }

        private func updateHosts(
            with data: Data,
            content: (Element) -> Content
        ) {
            let currentIDs = Set(data.map { $0[keyPath: id] })

            let removedIDs = hosts.keys.filter { !currentIDs.contains($0) }

            for id in removedIDs {
                guard let host = hosts[id] else { continue }

                remove(host)
                hosts[id] = nil

                if visibleID == id {
                    visibleID = nil
                }
            }

            for element in data {
                if let host = hosts[element[keyPath: id]] {
                    host.content = content(element)
                } else {
                    let host = HostingController(content: content(element))
                    host.disableSafeArea = true
                    host.view.backgroundColor = .clear
                    hosts[element[keyPath: id]] = host
                }
            }
        }

        private func select(_ selection: ID?, in container: UIViewController) {
            let previousHost = visibleID.flatMap { hosts[$0] }
            let host = selection.flatMap { hosts[$0] }
            guard host !== previousHost else { return }

            if let host, host.parent !== container {
                remove(host)
                add(host, to: container, alpha: 0)
            }

            visibleID = host == nil ? nil : selection
            transition(from: previousHost, to: host)
        }

        private func add(_ host: UIViewController, to container: UIViewController, alpha: CGFloat = 1) {
            container.addChild(host)
            container.view.addSubview(host.view)

            host.view.translatesAutoresizingMaskIntoConstraints = false
            host.view.alpha = alpha

            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
                host.view.topAnchor.constraint(equalTo: container.view.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: container.view.bottomAnchor),
            ])

            host.didMove(toParent: container)
        }

        private func transition(from oldHost: UIViewController?, to newHost: UIViewController?) {
            transitionID += 1
            let currentTransitionID = transitionID

            // Interrupted transitions may leave an outgoing host attached.
            for host in hosts.values where host !== oldHost && host !== newHost {
                remove(host)
            }

            UIView.animate(
                withDuration: 0.2,
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

            host.view.layer.removeAllAnimations()
            host.willMove(toParent: nil)
            host.view.removeFromSuperview()
            host.removeFromParent()
        }
    }
}
