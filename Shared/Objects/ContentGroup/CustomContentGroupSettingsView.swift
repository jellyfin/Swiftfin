//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

struct CustomContentGroupSettingsView: View {

    @StoredValue
    private var customContentGroup: ContentGroupProviderSetting

    @State
    private var temporaryCustomContentGroup: StoredContentGroupProvider = .init(
        displayTitle: "Custom",
        id: "custom_\(UUID().uuidString)",
        systemImage: "heart.fill",
        groups: [.nextUp(
            id: UUID().uuidString,
            posterDisplayType: .portrait,
            posterSize: .small
        )]
    )

    @State
    private var displayTitle: String = ""

    init(id: String) {
        self._customContentGroup = StoredValue(
            .User.customContentGroup(id: id)
        )

        if case let .custom(provider) = customContentGroup {
            self._temporaryCustomContentGroup = State(
                initialValue: provider
            )
        }
    }

    var body: some View {
        Form {

            TextField(L10n.title, text: $temporaryCustomContentGroup.displayTitle)

//            ForEach(temporaryCustomContentGroup.groups, id: \.hashValue) { groupSetting in
//                Button(groupSetting.group.displayTitle) {
//                    temporaryCustomContentGroup.groups
//                        .removeAll(where: { $0 == groupSetting })
//                }
//            }
        }
        .navigationTitle("Custom")
        .topBarTrailing {
            Button("Add") {
                temporaryCustomContentGroup.groups.append(
                    .library(
                        id: UUID().uuidString,
                        displayTitle: "Movies",
                        libraryID: "f137a2dd21bbc1b99aa5c0f6bf02a805",
                        filters: .init(),
                        posterDisplayType: PosterDisplayType.allCases.randomElement()!,
                        posterSize: PosterDisplayType.Size.allCases.randomElement()!
                    )
//                    .nextUp(
//                        posterDisplayType: PosterDisplayType.allCases.randomElement()!,
//                        posterSize: PosterDisplayType.Size.allCases.randomElement()!
//                    )
                )
            }

            Button("Save") {
                customContentGroup = .custom(
                    temporaryCustomContentGroup
                )
            }
//            .buttonStyle(.toolbarPill)
        }
    }
}
