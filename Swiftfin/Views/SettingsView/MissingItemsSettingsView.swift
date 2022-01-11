//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct MissingItemsSettingsView: View {

	@Default(.shouldShowMissingSeasons)
	var shouldShowMissingSeasons

	@Default(.shouldShowMissingEpisodes)
	var shouldShowMissingEpisodes

	var body: some View {
		Form {
			Section {
				Toggle("Show Missing Seasons", isOn: $shouldShowMissingSeasons)
				Toggle("Show Missing Episodes", isOn: $shouldShowMissingEpisodes)
			} header: {
                Text("Missing Items")
			}
		}
	}
}
