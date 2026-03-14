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

    struct CastAndCrewHStack: View {

        @Router
        private var router

        let people: [BaseItemPerson]

        var body: some View {
            PosterHStack(
                title: L10n.castAndCrew,
                type: .portrait,
                items: people.filter { person in
                    person.type?.isSupported ?? false
                }
            ) { person in
                router.route(to: .item(item: .init(person: person)))
            }
        }
    }
}
