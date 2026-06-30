//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Recording

struct RecordingMenu: View {

    // @ObservedObject
    // var viewModel: RecordingViewModel

    var body: some View {
        Menu {
            Button(L10n.record) {
                // viewModel.send(.record)
            }

            Button(L10n.recordSeries) {
                // viewModel.send(.recordSeries)
            }
        } label: {
            Label(L10n.recording, systemImage: "record.circle")
        }
        .buttonStyle(.tintedMaterial(tint: .red, foregroundColor: .primary))
        .disabled(true)
    }
}
