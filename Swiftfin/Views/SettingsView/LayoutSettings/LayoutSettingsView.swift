//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct LayoutSettingsView: View {

    @Default(.Experimental.layout)
    private var isExperimentEnabled
    @Default(.Customization.advancedLayout)
    private var isAdvanced

    @StoredValue(.User.layout)
    private var configuration

    private var usesAdvancedLayout: Bool {
        isExperimentEnabled && isAdvanced
    }

    @ContentBuilder
    var body: some View {
        Form(systemImage: "rectangle.3.group") {
            if isExperimentEnabled {
                Section {
                    Toggle(L10n.advanced, isOn: $isAdvanced)
                } footer: {
                    Text(L10n.advancedLayoutDescription)
                }
            }

            if usesAdvancedLayout {
                LayoutEditorSections(configuration: $configuration)
            } else {
                HomeSection()

                Section(L10n.posters) {
                    ForEach(HomePosterGroup.allCases) { group in
                        HomePosterSettingsView.Row(group: group)
                    }
                }
            }
        }
        .navigationTitle(L10n.layout)
    }
}
