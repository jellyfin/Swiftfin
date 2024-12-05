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

        let type: ItemElementType

        let matches: [Element]

        // MARK: - Body

        var body: some View {
            if name.isNotEmpty && matches.isNotEmpty {
                Section(L10n.matches) {
                    ForEach(matches, id: \.self) { match in
                        Button {
                            switch type {
                            case .genres, .tags:
                                name = match as! String
                                id = nil
                            case .studios:
                                let item = match as! NameGuidPair

                                name = item.name ?? L10n.unknown
                                id = item.id ?? L10n.unknown
                            case .people:
                                let person = match as! BaseItemPerson

                                name = person.name ?? L10n.unknown
                                id = person.id ?? L10n.unknown
                            }
                        } label: {
                            switch type {
                            case .genres, .tags:
                                Text(match as! String)
                            case .studios:
                                Text((match as! NameGuidPair).name ?? L10n.unknown)
                            case .people:
                                HStack {
                                    let person = (match as! BaseItemPerson)
                                    ZStack {
                                        Color.clear

                                        ImageView(person.portraitImageSources(maxWidth: 30))
                                            .failure {
                                                Image(systemName: "person.fill")
                                                    .foregroundStyle(.primary)
                                            }
                                    }
                                    .posterStyle(.portrait)
                                    .frame(width: 30, height: 90)
                                    .padding(.horizontal)

                                    Text((match as! BaseItemPerson).name ?? L10n.unknown)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                        .disabled(isSelected(match))
                    }
                }
            }
        }

        // MARK: - Is the Name the Current Element

        private func isSelected(_ element: Element) -> Bool {
            switch type {
            case .genres, .tags:
                return name == (element as! String)
            case .studios:
                return name == (element as! NameGuidPair).name
            case .people:
                return name == (element as! BaseItemPerson).name
            }
        }
    }
}
