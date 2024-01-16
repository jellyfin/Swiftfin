//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: manual dividers

struct LibraryItemRow<Item: Displayable & Poster>: View {

    @EnvironmentObject
    private var router: LibraryCoordinator.Router

    private let item: Item
    private var onSelect: () -> Void

    private let posterWidth: CGFloat = 60

    @ViewBuilder
    private func personAccessoryView(person: BaseItemPerson) -> some View {
        if let subtitle = person.subtitle {
            Text(subtitle)
                .font(.caption)
                .foregroundColor(Color(UIColor.lightGray))
        }
    }

    @ViewBuilder
    private func videoAccessoryView(item: BaseItemDto) -> some View {
        DotHStack {
            if item.type == .episode, let seasonEpisodeLocator = item.seasonEpisodeLocator {
                Text(seasonEpisodeLocator)
            } else if let premiereYear = item.premiereDateYear {
                Text(premiereYear)
            }

            if let runtime = item.getItemRuntime() {
                Text(runtime)
            }

            if let officialRating = item.officialRating {
                Text(officialRating)
            }
        }
    }

    @ViewBuilder
    private var accessoryView: some View {
        if let item = item as? BaseItemDto {
            videoAccessoryView(item: item)
        } else if let person = item as? BaseItemPerson {
            personAccessoryView(person: person)
        }
    }

    // MARK: body

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(alignment: .center) {
                ZStack {
                    Color.clear

                    ImageView(item.portraitPosterImageSource(maxWidth: 60))
                }
                .frame(width: 60, height: 90)
                .posterStyle(.portrait)
                .posterShadow()

                VStack(alignment: .leading) {
                    Text(item.displayTitle)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    accessoryView
                        .eraseToAnyView()
                        .font(.caption)
                        .foregroundColor(Color(UIColor.lightGray))
                }
                .padding(.vertical)

                Spacer()
            }
        }
    }
}

extension LibraryItemRow {

    init(item: Item) {
        self.init(
            item: item,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
