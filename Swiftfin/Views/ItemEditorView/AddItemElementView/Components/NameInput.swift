//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AddItemComponentView {

    struct NameInput: View {

        @Binding
        var name: String
        var type: ItemElementType

        @Binding
        var personKind: PersonKind
        @Binding
        var personRole: String

        let validation: (String) -> Bool

        // MARK: - Body

        var body: some View {

            // MARK: Generic Inputs

            Section {
                TextField(L10n.name, text: $name)
                    .autocorrectionDisabled()
            } header: {
                Text(L10n.name)
            } footer: {
                if name.isEmpty || name == "" {
                    Label(
                        L10n.required,
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                } else {
                    if validation(name) {
                        Label(
                            L10n.existsOnServer,
                            systemImage: "checkmark.circle.fill"
                        )
                        .labelStyle(.sectionFooterWithImage(imageStyle: .green))
                    } else {
                        Label(
                            L10n.willBeCreatedOnServer,
                            systemImage: "checkmark.seal.fill"
                        )
                        .labelStyle(.sectionFooterWithImage(imageStyle: .blue))
                    }
                }
            }

            // MARK: People Inputs

            if type == .people {
                Section {
                    Picker(L10n.type, selection: $personKind) {
                        ForEach(PersonKind.allCases, id: \.self) { kind in
                            Text(kind.displayTitle).tag(kind)
                        }
                    }
                    if personKind == PersonKind.actor {
                        TextField(L10n.role, text: $personRole)
                            .autocorrectionDisabled()
                    }
                }
            }
        }
    }
}
