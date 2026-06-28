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

struct FadeContentTransitionView<Item: Hashable, Content: View>: UIViewRepresentable {

    private let item: Item
    private let duration: TimeInterval
    private let debounce: TimeInterval?
    private let content: (Item) -> Content

    init(
        item: Item,
        duration: TimeInterval = 0.35,
        debounce: TimeInterval? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.item = item
        self.duration = duration
        self.debounce = debounce
        self.content = content
    }

    func makeUIView(context: Context) -> UIFadeContentTransitionView {
        UIFadeContentTransitionView()
    }

    func updateUIView(_ uiView: UIFadeContentTransitionView, context: Context) {
        context.coordinator.scheduleUpdate(
            item: item,
            duration: duration,
            debounce: debounce,
            content: content,
            in: uiView
        )
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UIFadeContentTransitionView,
        context: Context
    ) -> CGSize? {
        uiView.sizeThatFits(proposal)
    }

    static func dismantleUIView(_ uiView: UIFadeContentTransitionView, coordinator: Coordinator) {
        coordinator.cancelScheduledWork()
        uiView.cancelTransition()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {

        private var currentContentID: AnyHashable?
        private var currentContent: HostedFadeContentTransitionContent<Content>?
        private var updateGeneration = 0
        private var debounceUpdate: DispatchWorkItem?

        func scheduleUpdate(
            item: Item,
            duration: TimeInterval,
            debounce: TimeInterval?,
            content: @escaping (Item) -> Content,
            in view: UIFadeContentTransitionView
        ) {
            updateGeneration += 1
            let generation = updateGeneration
            let id = AnyHashable(item)

            cancelScheduledWork()

            let update = DispatchWorkItem { [weak self, weak view] in
                guard let self,
                      let view,
                      self.updateGeneration == generation
                else { return }

                self.applyUpdate(
                    id: id,
                    duration: duration,
                    content: content(item),
                    generation: generation,
                    in: view
                )
            }

            guard currentContentID != id,
                  view.hasRetainedContent,
                  let debounce,
                  debounce > 0
            else {
                update.perform()
                return
            }

            debounceUpdate = update
            DispatchQueue.main.asyncAfter(deadline: .now() + debounce, execute: update)
        }

        func cancelScheduledWork() {
            debounceUpdate?.cancel()
            debounceUpdate = nil
        }

        private func applyUpdate(
            id: AnyHashable,
            duration: TimeInterval,
            content: Content,
            generation: Int,
            in view: UIFadeContentTransitionView
        ) {
            if currentContentID == id, let currentContent {
                currentContent.hostingController.rootView = content
                debounceUpdate = nil
                return
            }

            let hostingController = HostingController(content: content)
            hostingController.disablesSafeArea = true
            hostingController.view.backgroundColor = .clear

            let transitionContent = HostedFadeContentTransitionContent(
                id: id,
                view: hostingController.view,
                hostingController: hostingController
            )

            currentContentID = id
            currentContent = transitionContent
            debounceUpdate = nil

            view.update(
                to: transitionContent,
                duration: duration,
                generation: generation
            )
        }
    }
}

private final class HostedFadeContentTransitionContent<Content: View> {

    let id: AnyHashable
    let view: UIView
    let hostingController: UIHostingController<Content>

    init(
        id: AnyHashable,
        view: UIView,
        hostingController: UIHostingController<Content>
    ) {
        self.id = id
        self.view = view
        self.hostingController = hostingController
    }
}

final class UIFadeContentTransitionView: UIView {

    private var currentContent: AnyObject?
    private var currentContentView: UIView?
    private var incomingContent: AnyObject?
    private var incomingContentView: UIView?
    private var pendingContent: AnyObject?
    private var pendingContentView: UIView?
    private var pendingDuration: TimeInterval?
    private var pendingGeneration: Int?
    private var currentGeneration = 0
    private var animator: UIViewPropertyAnimator?

    fileprivate var hasRetainedContent: Bool {
        currentContentView != nil || incomingContentView != nil || pendingContentView != nil
    }

    override var intrinsicContentSize: CGSize {
        fittingSize
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width > 0,
              bounds.height > 0,
              let pendingContent,
              let pendingContentView,
              let pendingDuration,
              let pendingGeneration
        else { return }

        self.pendingContent = nil
        self.pendingContentView = nil
        self.pendingDuration = nil
        self.pendingGeneration = nil

        applyUpdate(
            content: pendingContent,
            contentView: pendingContentView,
            duration: pendingDuration,
            generation: pendingGeneration
        )
    }

    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize? {
        let fallbackSize = fittingSize
        let width = proposal.width ?? fallbackSize.width
        let height = proposal.height ?? fallbackSize.height

        return CGSize(
            width: max(width, 1),
            height: max(height, 1)
        )
    }

    fileprivate func update(
        to newContent: HostedFadeContentTransitionContent<some View>,
        duration: TimeInterval,
        generation: Int
    ) {
        currentGeneration = generation

        guard bounds.width > 0,
              bounds.height > 0
        else {
            animator?.stopAnimation(true)
            animator = nil
            incomingContentView?.removeFromSuperview()
            incomingContent = nil
            incomingContentView = nil
            pendingContent = newContent
            pendingContentView = newContent.view
            pendingDuration = duration
            pendingGeneration = generation
            invalidateIntrinsicContentSize()
            setNeedsLayout()
            return
        }

        applyUpdate(
            content: newContent,
            contentView: newContent.view,
            duration: duration,
            generation: generation
        )
    }

    fileprivate func cancelTransition() {
        animator?.stopAnimation(true)
        animator = nil
        incomingContentView?.removeFromSuperview()
        incomingContent = nil
        incomingContentView = nil
        pendingContent = nil
        pendingContentView = nil
        pendingDuration = nil
        pendingGeneration = nil
    }

    private func applyUpdate(
        content newContent: AnyObject,
        contentView newContentView: UIView,
        duration: TimeInterval,
        generation: Int
    ) {
        animator?.stopAnimation(true)
        animator = nil
        currentContentView?.alpha = 1

        incomingContentView?.removeFromSuperview()
        incomingContent = nil
        incomingContentView = nil

        let oldContentView = currentContentView
        oldContentView?.alpha = 1
        newContentView.alpha = oldContentView == nil ? 1 : 0
        addPinnedSubview(newContentView)

        guard oldContentView != nil, duration > 0 else {
            oldContentView?.removeFromSuperview()
            currentContent = newContent
            currentContentView = newContentView
            invalidateIntrinsicContentSize()
            return
        }

        incomingContent = newContent
        incomingContentView = newContentView

        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            oldContentView?.alpha = 0
            newContentView.alpha = 1
        }

        animator.addCompletion { [weak self] position in
            guard let self,
                  self.currentGeneration == generation,
                  position == .end
            else { return }

            oldContentView?.removeFromSuperview()
            self.currentContent = newContent
            self.currentContentView = newContentView
            self.incomingContent = nil
            self.incomingContentView = nil
            self.animator = nil
            self.invalidateIntrinsicContentSize()
        }

        self.animator = animator
        animator.startAnimation()
    }

    private var fittingSize: CGSize {
        let view = pendingContentView ?? incomingContentView ?? currentContentView
        let size = view?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize) ?? .zero

        return CGSize(
            width: max(size.width, 1),
            height: max(size.height, 1)
        )
    }

    private func addPinnedSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leftAnchor.constraint(equalTo: leftAnchor),
            view.rightAnchor.constraint(equalTo: rightAnchor),
        ])
    }
}
