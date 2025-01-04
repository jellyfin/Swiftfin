//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AddItemElementView {

    struct NameInput: View {

        // MARK: - Element Variables

        @Binding
        var name: String
        @Binding
        var personKind: PersonKind
        @Binding
        var personRole: String

        let type: ItemArrayElements
        let itemAlreadyExists: Bool

        // MARK: - Body

        var body: some View {
            nameView

            if type == .people {
                personView
            }
        }

        // MARK: - Name View

        private var nameView: some View {
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
                    if itemAlreadyExists {
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
        }

        // MARK: - Person View

        var personView: some View {
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
