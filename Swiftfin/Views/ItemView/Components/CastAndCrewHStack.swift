//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
                title: L10n.castAndCrew.localizedCapitalized,
                type: .portrait,
                items: people.filter { person in
                    person.type?.isSupported ?? false
                }
            ) { person, namespace in
                router.route(to: .item(item: .init(person: person)), in: namespace)
            }
            .trailing {
                SeeAllButton()
                    .onSelect {
                        router.route(to: .castAndCrew(people: people, itemID: nil))
                        router.route(to: .castAndCrew(people: people, itemID: nil))
                    }
            }
        }
    }
}
