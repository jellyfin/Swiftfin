//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: have `ImageView` failure view be an icon based on Element/BaseItemDto type

extension PagingLibraryView {

    struct LibraryRow: View {

        private let item: Element
        private var onSelect: () -> Void

        @ViewBuilder
        private func itemAccessoryView(item: BaseItemDto) -> some View {
            DotHStack {
                if item.type == .episode, let seasonEpisodeLocator = item.seasonEpisodeLabel {
                    Text(seasonEpisodeLocator)
                } else if let premiereYear = item.premiereDateYear {
                    Text(premiereYear)
                }

                if let runtime = item.runTimeLabel {
                    Text(runtime)
                }

                if let officialRating = item.officialRating {
                    Text(officialRating)
                }
            }
        }

        @ViewBuilder
        private func personAccessoryView(person: BaseItemPerson) -> some View {
            if let subtitle = person.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.lightGray))
            }
        }

        @ViewBuilder
        private var accessoryView: some View {
            switch item {
            case let element as BaseItemDto:
                itemAccessoryView(item: element)
            case let element as BaseItemPerson:
                personAccessoryView(person: element)
            default:
                fatalError("Used an unexpected type within a `PagingLibaryView`?")
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
                            .font(.caption)
                            .foregroundColor(Color(UIColor.lightGray))
                    }
                    .padding(.vertical)

                    Spacer()
                }
            }
        }
    }
}

extension PagingLibraryView.LibraryRow {

    init(item: Element) {
        self.init(
            item: item,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
