//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

struct SFSymbolButton: UIViewRepresentable {

	let systemName: String
	let action: () -> Void
	private let pointSize: CGFloat

	init(systemName: String, pointSize: CGFloat = 24, action: @escaping () -> Void) {
		self.systemName = systemName
		self.action = action
		self.pointSize = pointSize
	}

	func makeUIView(context: Context) -> some UIButton {
		var configuration = UIButton.Configuration.plain()
		configuration.cornerStyle = .capsule

		let buttonAction = UIAction(title: "") { _ in
			self.action()
		}

		let button = UIButton(configuration: configuration, primaryAction: buttonAction)

		let symbolImageConfig = UIImage.SymbolConfiguration(pointSize: pointSize)
		let symbolImage = UIImage(systemName: systemName, withConfiguration: symbolImageConfig)

		button.setImage(symbolImage, for: .normal)

		return button
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {}
}

extension SFSymbolButton: Hashable {
	static func == (lhs: SFSymbolButton, rhs: SFSymbolButton) -> Bool {
		lhs.systemName == rhs.systemName
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(systemName)
	}
}
