//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-device-rotation
import Foundation
import SwiftUI

// Our custom view modifier to track rotation and
// call our action
struct DeviceRotationViewModifier: ViewModifier {
	let action: (UIDeviceOrientation) -> Void

	func body(content: Content) -> some View {
		content
			.onAppear()
			.onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
				action(UIDevice.current.orientation)
			}
	}
}

// A View wrapper to make the modifier easier to use
extension View {
	func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
		self.modifier(DeviceRotationViewModifier(action: action))
	}
}
