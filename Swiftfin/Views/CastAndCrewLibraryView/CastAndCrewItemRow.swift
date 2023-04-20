//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension CastAndCrewLibraryView {

    struct CastAndCrewItemRow: View {

        @EnvironmentObject
        private var router: CastAndCrewLibraryCoordinator.Router

        private let person: BaseItemPerson
        private var onSelect: () -> Void

        var body: some View {
            Button {
                onSelect()
            } label: {
                HStack(alignment: .bottom) {
                    ImageView(person.portraitPosterImageSource(maxWidth: 60))
                        .posterStyle(type: .portrait, width: 60)

                    VStack(alignment: .leading) {
                        Text(person.displayTitle)
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        if let subtitle = person.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(Color(UIColor.lightGray))
                        }
                    }
                    .padding(.vertical)

                    Spacer()
                }
            }
        }
    }
}

extension CastAndCrewLibraryView.CastAndCrewItemRow {
    init(person: BaseItemPerson) {
        self.person = person
        self.onSelect = {}
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
