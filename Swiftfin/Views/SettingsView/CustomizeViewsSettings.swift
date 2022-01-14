//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CustomizeViewsSettings: View {

	@Default(.showPosterLabels)
	var showPosterLabels
	@Default(.showCastAndCrew)
	var showCastAndCrew

	var body: some View {
		Form {
			Section {

				Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)
				Toggle(L10n.showCastAndCrew, isOn: $showCastAndCrew)

			} header: {
				L10n.customize.text
			}
		}
	}
}
