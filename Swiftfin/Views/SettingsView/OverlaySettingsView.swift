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
            Section(header: L10n.overlay.text) {
                Picker(L10n.overlayType, selection: $overlayType) {
					ForEach(OverlayType.allCases, id: \.self) { overlay in
						Text(overlay.label).tag(overlay)
					}
				}

                Toggle(isOn: $shouldShowPlayPreviousItem) {
                    HStack {
                        Image(systemName: "chevron.left.circle")
                        L10n.playPreviousItem.text
                    }
                }
                
                Toggle(isOn: $shouldShowPlayNextItem) {
                    HStack {
                        Image(systemName: "chevron.right.circle")
                        L10n.playNextItem.text
                    }
                }
                
                Toggle(isOn: $shouldShowAutoPlay) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        L10n.autoPlay.text
                    }
                }
                
                Toggle(L10n.editJumpLengths, isOn: $shouldShowJumpButtonsInOverlayMenu)
			}
		}
	}
}
