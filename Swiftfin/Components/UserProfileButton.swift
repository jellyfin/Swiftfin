//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct UserProfileButton: View {

    let user: UserDto
    private var action: () -> Void

    init(user: UserDto) {
        self.user = user
        self.action = {}
    }

    init(user: SwiftfinStore.State.User) {
        self.init(user: .init(name: user.username, id: user.id))
    }

    var body: some View {
        VStack(alignment: .center) {
            Button {
                action()
            } label: {
                ImageView(user.profileImageSource(maxWidth: 120, maxHeight: 120))
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
        var copy = self
        copy.action = action
        return copy
    }
}
