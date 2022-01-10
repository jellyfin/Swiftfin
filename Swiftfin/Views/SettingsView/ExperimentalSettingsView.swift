//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ExperimentalSettingsView: View {

	@Default(.Experimental.syncSubtitleStateWithAdjacent)
	var syncSubtitleStateWithAdjacent

	var body: some View {
		Form {
			Section {

				Toggle("Sync Subtitles with Adjacent Episodes", isOn: $syncSubtitleStateWithAdjacent)

			} header: {
                L10n.experimental.text
			}
		}
	}
}
