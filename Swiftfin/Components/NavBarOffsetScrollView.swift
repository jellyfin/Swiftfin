//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

struct NavBarOffsetScrollView<Body: View>: UIViewControllerRepresentable {

	let headerHeight: CGFloat
	let body: () -> Body

	init(headerHeight: CGFloat, @ViewBuilder body: @escaping () -> Body) {
		self.headerHeight = headerHeight
		self.body = body
	}

	func makeUIViewController(context: Context) -> NavBarOffsetScrollViewController<Body> {
		NavBarOffsetScrollViewController(headerHeight: headerHeight, body: body)
	}

	func updateUIViewController(_ uiViewController: NavBarOffsetScrollViewController<Body>, context: Context) {
		uiViewController.update(self.body, self.headerHeight)
	}
}

class NavBarOffsetScrollViewController<Body: View>: UIViewController, UIScrollViewDelegate {

	private lazy var scrollView = makeScrollView()
	private lazy var bodyHostingController = makeBodyHostingController()
	private lazy var navBarBlurView = makeNavBarBlurView()

	private var body: () -> Body
	private var headerHeight: CGFloat

	init(headerHeight: CGFloat, body: @escaping () -> Body) {
		self.body = body
		self.headerHeight = headerHeight

		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func update(_ newBody: () -> Body, _ headerHeight: CGFloat) {
		self.bodyHostingController.rootView = newBody()
		self.headerHeight = headerHeight
		self.scrollView.updateConstraintsIfNeeded()
		self.scrollView.layoutIfNeeded()
		self.view.updateConstraintsIfNeeded()
		self.view.layoutIfNeeded()
	}

	private func setupSubviews() {
		view.addSubview(scrollView)
		scrollView.addSubview(bodyHostingController.view)
		view.addSubview(navBarBlurView)
		navBarBlurView.alpha = 0
	}

	private func setupConstraints() {
		let statusBarHeight = getStatusBarHeight()
		let navbarHeight: CGFloat = 88

		NSLayoutConstraint.activate([
			scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: -statusBarHeight - navbarHeight),
			scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
		])
		NSLayoutConstraint.activate([
			bodyHostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor,
			                                                constant: statusBarHeight + navbarHeight),
			bodyHostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
			bodyHostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
			bodyHostingController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
		])
		NSLayoutConstraint.activate([
			navBarBlurView.topAnchor.constraint(equalTo: view.topAnchor, constant: -statusBarHeight - navbarHeight),
			navBarBlurView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			navBarBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			navBarBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
		])
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		bodyHostingController.willMove(toParent: self)
		setupSubviews()
		setupConstraints()
		bodyHostingController.didMove(toParent: self)

		scrollView.delegate = self
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.navigationController?.navigationBar
			.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0)]
		self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
		self.navigationController?.navigationBar.shadowImage = UIImage()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
		self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
		self.navigationController?.navigationBar.shadowImage = nil
	}

	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let maxHeight: CGFloat = headerHeight + 10
		let currentProgress = (scrollView.contentOffset.y - headerHeight) * 8 / maxHeight
		let offset = min(max(currentProgress, 0), 1)
		self.navigationController?.navigationBar
			.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(offset)]
		navBarBlurView.alpha = offset
	}

	private func makeScrollView() -> UIScrollView {
		let scrollView = UIScrollView()
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.showsVerticalScrollIndicator = false
		return scrollView
	}

	private func makeBodyHostingController() -> UIHostingController<Body> {
		let hostingController = UIHostingController(rootView: body())
		hostingController.view.translatesAutoresizingMaskIntoConstraints = false
		return hostingController
	}

	private func makeNavBarBlurView() -> UIVisualEffectView {
		let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
		blurView.translatesAutoresizingMaskIntoConstraints = false
		return blurView
	}

	private func getStatusBarHeight() -> CGFloat {
		let scenes = UIApplication.shared.connectedScenes
		let windowScene = scenes.first as? UIWindowScene
		let window = windowScene?.windows.first
		let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
		return statusBarHeight
	}
}
