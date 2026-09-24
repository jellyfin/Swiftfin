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
struct SupplementTabView<Content: View>: PlatformViewControllerRepresentable {

    let data: [any MediaPlayerSupplement]
    let selection: Binding<String?>

    @ViewBuilder
    let content: (any MediaPlayerSupplement) -> Content

    private var selectionPresented: (String) -> Void = { _ in }

    func onSelectionPresented(_ action: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.selectionPresented = action
        return copy
    }

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
            selectionPresented: selectionPresented,
            content: content
        )
    }

    static func dismantleUIViewController(_: UIViewController, coordinator: Coordinator) {
        coordinator.removeAll()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {

        weak var container: UIViewController?

        private var hosts: [String: HostingController<Content>] = [:]
        private weak var visibleHost: HostingController<Content>?
        private var transitionID: Int = 0
        private var selectionPresented: (String) -> Void = { _ in }

        func sync(
            data: [any MediaPlayerSupplement],
            selection: String?,
            selectionPresented: @escaping (String) -> Void,
            @ViewBuilder content: (any MediaPlayerSupplement) -> Content
        ) {
            guard let container else { return }

            self.selectionPresented = selectionPresented

            let ids = Set(data.map(\.id))
            for id in hosts.keys.filter({ !ids.contains($0) }) {
                guard let host = hosts.removeValue(forKey: id) else { continue }
                remove(host)
                if visibleHost === host {
                    visibleHost = nil
                }
            }
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
            select(selection, in: container)
        }

        func removeAll() {
            transitionID += 1

            for host in hosts.values {
                remove(host)
            }

            hosts.removeAll()
            visibleHost = nil
        }

        private func select(_ selection: String?, in container: UIViewController) {
            let previousHost = visibleHost
            let host = selection.flatMap { hosts[$0] }
            guard host !== previousHost else { return }

            if let host, host.parent !== container {
                remove(host)
                add(host, to: container, alpha: 0)
            }

            visibleHost = host
            transition(from: previousHost, to: host, selection: selection)
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

        private func transition(from oldHost: UIViewController?, to newHost: UIViewController?, selection: String?) {
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

                // Guest panels become focusable after their host finishes appearing.
                if newHost != nil, let selection {
                    self.selectionPresented(selection)
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
