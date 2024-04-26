//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

#warning("TODO: remove/refactor for public users")

// TODO: remove client passing and mirror how other images are made

struct UserProfileButton: View {

    private let client: JellyfinClient
    private let user: UserDto
    private var onSelect: () -> Void

    init(user: UserDto, client: JellyfinClient) {
        self.client = client
        self.user = user
        self.onSelect = {}
    }

    private var personView: some View {
        SystemImageContentView(systemName: "person.fill")
    }

    var body: some View {
        VStack(alignment: .center) {
            Button {
                onSelect()
            } label: {
                ZStack {
                    Color.clear

                    ImageView(user.profileImageSource(client: client, maxWidth: 120, maxHeight: 120))
                        .placeholder { _ in
                            personView
                        }
                        .failure {
                            personView
                        }
                }
                .aspectRatio(1, contentMode: .fill)
                .cornerRadius(ratio: 1 / 30, of: \.width)
            }

            Text(user.name ?? .emptyDash)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
    }
}

extension UserProfileButton {

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
