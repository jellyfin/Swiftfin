//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer {

    struct LoadingView: View {

        @Router
        private var router

        var body: some View {
            ZStack {
                Color.black

                VStack(spacing: 10) {

                    Text(L10n.retrievingMediaInformation)
                        .foregroundColor(.white)

                    ProgressView()

                    Button {
                        router.dismiss()
                    } label: {
                        Text(L10n.cancel)
                            .foregroundColor(.red)
                            .padding()
                            .overlay {
                                Capsule()
                                    .stroke(Color.red, lineWidth: 1)
                            }
                    }
                }
            }
        }
    }
}
