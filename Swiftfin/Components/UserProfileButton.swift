//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: remove client passing and mirror how other images are made

struct UserProfileButton: View {

    private let client: JellyfinClient
    private let user: UserDto
    private var onSelect: () -> Void

    // TODO: Why both?
    init(user: UserDto, client: JellyfinClient) {
        self.client = client
        self.user = user
        self.onSelect = {}
    }

    init(user: UserState, client: JellyfinClient) {
        self.client = client
        self.user = .init(id: user.id, name: user.username)
        self.onSelect = {}
    }

    var body: some View {
        VStack(alignment: .center) {
            Button {
                onSelect()
            } label: {
                ImageView(user.profileImageSource(client: client, maxWidth: 120, maxHeight: 120))
                    .failure {
                        ZStack {
                            Color.secondarySystemFill
                                .opacity(0.5)

                            Image(systemName: "person.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                        }
                    }
                    .clipShape(Circle())
            }
            .frame(width: 120, height: 120)

            Text(user.name ?? .emptyDash)
        }
    }
}

extension UserProfileButton {

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
