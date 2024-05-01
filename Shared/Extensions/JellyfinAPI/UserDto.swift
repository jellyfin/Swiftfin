//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import Get
import JellyfinAPI
import UIKit

#warning("TODO: cleanup")

extension UserDto {

    func profileImageSource(
        client: JellyfinClient,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) -> ImageSource {
        UserState(
            id: id ?? "",
            serverID: "",
            username: ""
        )
        .profileImageSource(
            client: client,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )
    }
}
