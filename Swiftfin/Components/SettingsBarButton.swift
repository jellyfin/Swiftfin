//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

// Want the default navigation bar `Image(systemName:)` styling
// but using within `ImageView.placeholder/failure` ruins it.
// Need to do manual checking of image loading.
struct SettingsBarButton: View {

    @State
    private var isUserImage = false

    let server: ServerState
    let user: UserState
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "gearshape.fill")
                .visible(!isUserImage)
                .overlay {
                    ZStack {
                        Color.clear

                        ImageView(user.profileImageSource(
                            client: server.client,
                            maxWidth: 120
                        ))
                        .image { image in
                            image
                                .clipShape(.circle)
                                .aspectRatio(1, contentMode: .fit)
                                .posterBorder(ratio: 1 / 2, of: \.width)
                                .onAppear {
                                    isUserImage = true
                                }
                        }
                        .placeholder { _ in
                            Color.clear
                        }
                    }
                }
        }
        .accessibilityLabel(L10n.settings)
    }
}
