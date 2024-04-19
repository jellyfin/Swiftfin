//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

struct UserProfileButton: View {

    @Injected(Container.userSession)
    private var userSession

    @FocusState
    private var isFocused: Bool

    let user: UserDto
    private var action: () -> Void

    init(user: UserDto) {
        self.user = user
        self.action = {}
    }

    init(user: UserState) {
        self.init(user: .init(id: user.id, name: user.username))
    }

    var body: some View {
        VStack(alignment: .center) {
            Button {
                action()
            } label: {
                ZStack {
                    Color.clear

                    ImageView(user.profileImageSource(client: userSession.client, maxWidth: 250, maxHeight: 250))
                        .failure {
                            Image(systemName: "person.fill")
                                .resizable()
                                .edgePadding()
                        }
                }
                .aspectRatio(1, contentMode: .fill)
            }
            .buttonStyle(.card)
            .focused($isFocused)

            Text(user.name ?? .emptyDash)
                .foregroundColor(isFocused ? .primary : .secondary)
        }
    }
}

extension UserProfileButton {

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.action, with: action)
    }
}
