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

    struct MatchesSection: View {

        @Binding
        var id: String?
        @Binding
        var name: String

        let matches: [Element]

        // MARK: - Body

        var body: some View {
            if name.isNotEmpty && matches.isNotEmpty {
                Section(L10n.matches) {
                    ForEach(matches, id: \.self) { suggestion in
                        if let newName = elementToName(suggestion) {
                            Button(newName) {
                                name = newName
                                id = elementToId(suggestion)
                            }
                            .foregroundStyle(.primary)
                            .disabled(name == newName)
                        }
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

        // MARK: - Format the Element into its Id

        private func elementToId(_ element: Element) -> String? {
            if let nameGuidPair = element as? NameGuidPair {
                return nameGuidPair.id
            } else if let baseItemPerson = element as? BaseItemPerson {
                return baseItemPerson.id
            }
            return nil
        }
    }
}
