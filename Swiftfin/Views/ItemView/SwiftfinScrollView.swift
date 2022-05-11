//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

struct SwiftfinScrollView<Header: View, Body: View>: UIViewControllerRepresentable {

	let headerHeight: CGFloat
	let header: () -> Header
	let body: () -> Body

	init(headerHeight: CGFloat, @ViewBuilder _ header: @escaping () -> Header, @ViewBuilder body: @escaping () -> Body) {
		self.headerHeight = headerHeight
		self.header = header
		self.body = body
	}

	func makeUIViewController(context: Context) -> SwiftfinScrollViewController<Header, Body> {
		SwiftfinScrollViewController(headerHeight: headerHeight, header: header(), content: body())
	}

	func updateUIViewController(_ uiViewController: SwiftfinScrollViewController<Header, Body>, context: Context) {
		uiViewController.update()
	}
}

class SwiftfinScrollViewController<Header: View, Body: View>: UIViewController, UIScrollViewDelegate {

	private lazy var scrollView = makeScrollView()
	private lazy var headerHostingController = makeHeaderHostingController()
	private lazy var bodyHostingController = makeBodyHostingController()
	private lazy var navBarBlurView = makeNavBarBlurView()

	private let headerHeight: CGFloat
	private let header: Header
	private var body: Body
	private var originalHeaderHeightConstraint = NSLayoutConstraint()

	init(headerHeight: CGFloat, header: Header, content: Body) {
		self.headerHeight = headerHeight
		self.header = header
		self.body = content

		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func update() {
		self.bodyHostingController = makeBodyHostingController()
		self.view.layoutSubviews()
		self.scrollView.layoutSubviews()
	}

	private func setupSubviews() {
		view.addSubview(headerHostingController.view)
		view.addSubview(scrollView)
		scrollView.addSubview(bodyHostingController.view)
		view.addSubview(navBarBlurView)
		navBarBlurView.alpha = 0
	}

	private func setupConstraints() {
		let statusBarHeight = getStatusBarHeight()
		let navbarHeight: CGFloat = 88

		originalHeaderHeightConstraint = headerHostingController.view.heightAnchor
			.constraint(equalToConstant: headerHeight + statusBarHeight + navbarHeight)

		NSLayoutConstraint.activate([
			headerHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			headerHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			headerHostingController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: -statusBarHeight - navbarHeight),
			originalHeaderHeightConstraint,
		])
		NSLayoutConstraint.activate([
			scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: -statusBarHeight - navbarHeight),
			scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
		])
		NSLayoutConstraint.activate([
			bodyHostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor,
			                                                constant: headerHeight + navbarHeight + statusBarHeight - 60),
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

		scrollView.delegate = self
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		headerHostingController.willMove(toParent: self)
		bodyHostingController.willMove(toParent: self)
		setupSubviews()
		setupConstraints()
		headerHostingController.didMove(toParent: self)
		bodyHostingController.didMove(toParent: self)

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

		let minHeight: CGFloat = headerHeight - 100
		let maxHeight: CGFloat = minHeight + 5

		let offset = min(max((scrollView.contentOffset.y - minHeight) / maxHeight, 0), 1)
		self.navigationController?.navigationBar
			.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(offset)]
		navBarBlurView.alpha = offset

		if scrollView.contentOffset.y <= 0 {
			let statusBarHeight = getStatusBarHeight()
			let navbarHeight: CGFloat = 88
			originalHeaderHeightConstraint.constant = headerHeight + statusBarHeight + navbarHeight - scrollView.contentOffset.y
		}
	}

	private func makeScrollView() -> UIScrollView {
		let scrollView = UIScrollView()
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.showsVerticalScrollIndicator = false
		return scrollView
	}

	private func makeHeaderHostingController() -> UIHostingController<Header> {
		let hostingController = UIHostingController(rootView: header)
		hostingController.view.translatesAutoresizingMaskIntoConstraints = false
		return hostingController
	}

	private func makeBodyHostingController() -> UIHostingController<Body> {
		let hostingController = UIHostingController(rootView: body)
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
