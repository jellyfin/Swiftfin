//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// Doesn't look the best even with `ScaledMetric` or other scaling mechanisms.
// Apple TV app doesn't scale either ... so don't worry too much
struct BackButtonView: View {

    @ObservedObject
    var driver: Driver

    private var chevron: some View {
        Image(systemName: "chevron.left")
            .symbolRenderingMode(.palette)
            .scaleEffect(driver.isChevron ? 1 : 0.7)
    }

    var body: some View {
        Button {
            driver.action()
        } label: {
            chevron
                .font(.system(size: 22, weight: .medium))
                .padding(10)
                .background {
                    Circle()
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .scaleEffect(0.7)
                        .opacity(driver.isChevron ? 0 : 1)
                }
                .overlay {
                    chevron
                        .font(.system(size: 22, weight: .heavy))
                        .opacity(driver.isChevron ? 0 : 1)
                }
                .offset(x: driver.isChevron ? -24 : -20)
                .frame(width: 50, height: 50)
                .foregroundStyle(driver.isChevron ? Color.accentColor : Color.black)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.3), value: driver.isChevron)
    }
}

class Driver: ObservableObject {

    @Published
    var isChevron = false

    var action: () -> Void = {}

    var postTransitionAction: (Bool) -> Void = { _ in }
    var isTransitioning = false

    private var transitionPostAction: DispatchWorkItem?

    func transition(toChevron: Bool) {
        isChevron = toChevron
        isTransitioning = true

        let newPostAction = DispatchWorkItem { [weak self] in
            guard let self else { return }
            isTransitioning = false
            postTransitionAction(toChevron)
        }

        transitionPostAction?.cancel()
        transitionPostAction = newPostAction

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: newPostAction)
    }
}

class UIBackButtonTransitionView<Content: View>: UIHostingController<Content> {

    private var lastAlpha: CGFloat = 0

    private var driver: Driver!
    private var customButton: _UIHostingView<BackButtonView>!

    override func viewDidLoad() {
        super.viewDidLoad()

        driver = Driver()

        driver.action = { [weak self] in
            guard let self else { return }

            if let vcs = navigationController?.viewControllers, vcs.count > 1 {
                navigationController?.popViewController(animated: true)
            } else {
                topNavigationController?.popViewController(animated: true)
            }
        }

        driver.postTransitionAction = { [weak self] isChevron in
            guard let parent = self?.parent, let customButton = self?.customButton else { return }

            if isChevron {
                parent.navigationItem.leftBarButtonItem = nil
                parent.navigationItem.leftItemsSupplementBackButton = true
            } else {
                let backBarButton = UIBarButtonItem(customView: customButton)
                parent.navigationItem.leftBarButtonItem = backBarButton
                parent.navigationItem.leftItemsSupplementBackButton = false
            }
        }

        customButton = _UIHostingView(rootView: BackButtonView(driver: driver))
    }

    func scrollViewDidScroll(_ offset: CGFloat, start: CGFloat, end: CGFloat) {

        guard start > 0, end > 0 else { return }

        let diff = end - start
        let currentProgress = (offset - start) / diff
        let alpha = clamp(currentProgress, min: 0, max: 1)

        // button

        let shouldBeChevron = alpha >= 0.5

        if driver.isChevron != shouldBeChevron {
            driver.transition(toChevron: shouldBeChevron)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let parent else { return }

        if lastAlpha < 0.5 {
            let backBarButton = UIBarButtonItem(customView: customButton)
            parent.navigationItem.leftBarButtonItem = backBarButton
            parent.navigationItem.leftItemsSupplementBackButton = false

            driver.isChevron = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        driver.isChevron = lastAlpha >= 0.5
    }
}

extension UIViewController {

    var topNavigationController: UINavigationController? {
        var top: UINavigationController? = navigationController

        while let parent = top?.navigationController {
            top = parent
        }

        return top
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {

    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
