//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct OverlaySettingsView: View {

	@Default(.overlayType)
	var overlayType
	@Default(.shouldShowPlayPreviousItem)
	var shouldShowPlayPreviousItem
	@Default(.shouldShowPlayNextItem)
	var shouldShowPlayNextItem
	@Default(.shouldShowAutoPlay)
	var shouldShowAutoPlay
	@Default(.shouldShowJumpButtonsInOverlayMenu)
	var shouldShowJumpButtonsInOverlayMenu

	var body: some View {
		Form {
			Section(header: Text("Overlay")) {
				Picker("Overlay Type", selection: $overlayType) {
					ForEach(OverlayType.allCases, id: \.self) { overlay in
						Text(overlay.label).tag(overlay)
					}
				}

				Toggle("\(Image(systemName: "chevron.left.circle")) Play Previous Item", isOn: $shouldShowPlayPreviousItem)
				Toggle("\(Image(systemName: "chevron.right.circle")) Play Next Item", isOn: $shouldShowPlayNextItem)
				Toggle("\(Image(systemName: "play.circle.fill")) Auto Play", isOn: $shouldShowAutoPlay)
				Toggle("Edit Jump Lengths", isOn: $shouldShowJumpButtonsInOverlayMenu)
			}
		}
	}
}
