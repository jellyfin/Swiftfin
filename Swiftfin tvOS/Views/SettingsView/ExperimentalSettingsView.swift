//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ExperimentalSettingsView: View {

    @Default(.Experimental.forceDirectPlay)
    private var forceDirectPlay
    @Default(.Experimental.liveTVForceDirectPlay)
    private var liveTVForceDirectPlay

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "gearshape")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {

                Section("Video Player") {

                    Toggle("Force Direct Play", isOn: $forceDirectPlay)
                }

                Section("Live TV") {

                    Toggle("Live TV Force Direct Play", isOn: $liveTVForceDirectPlay)
                }
            }
            .navigationTitle(L10n.experimental)
    }
}
