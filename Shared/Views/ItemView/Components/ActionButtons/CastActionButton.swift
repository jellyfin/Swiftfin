//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct CastActionButton<Label: View>: View {

        @Router
        private var router

        @StateObject
        private var viewModel = CastViewModel()

        let provider: MediaPlayerItemProvider
        @ViewBuilder
        let label: (Bool) -> Label

        var body: some View {
            Button {
                router.route(to: .remoteControl(provider: provider))
            } label: {
                label(viewModel.isPlaying(item: provider.item))
            }
            .onFirstAppear {
                viewModel.refresh()
            }
        }
    }
}
