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

        let matches: [Element]

        // MARK: - Body

        var body: some View {
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
                    if matches.contains(where: { elementToName($0) == name }) {
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

        // MARK: - Format the Element into its Name

        private func elementToName(_ element: Element) -> String? {
            if let stringElement = element as? String {
                return stringElement
            } else if let nameGuidPair = element as? NameGuidPair {
                return nameGuidPair.name
            } else if let baseItemPerson = element as? BaseItemPerson {
                return baseItemPerson.name
            }
            return nil
        }
    }
}
