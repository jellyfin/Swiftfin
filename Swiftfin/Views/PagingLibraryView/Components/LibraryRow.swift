//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension PagingLibraryView {

    struct LibraryRow: View {

        @State
        private var contentWidth: CGFloat = 0

        private let item: Element
        private var onSelect: () -> Void
        private let posterType: PosterType

        private func imageView(from element: Element) -> ImageView {
            switch posterType {
            case .portrait:
                ImageView(element.portraitPosterImageSource(maxWidth: 60))
            case .landscape:
                ImageView(element.landscapePosterImageSources(maxWidth: 110, single: false))
            }
        }

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
                AssertionFailureView("Used an unexpected type within a `PagingLibaryView`?")
            }
        }

        // MARK: body

        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                Button {
                    onSelect()
                } label: {
                    HStack(alignment: .center, spacing: EdgeInsets.defaultEdgePadding) {
                        ZStack {
                            Color.clear

                            imageView(from: item)
                                .failure {
                                    SystemImageContentView(systemName: item.typeSystemImage)
                                }
                        }
                        .posterStyle(posterType)
                        .frame(width: posterType == .landscape ? 110 : 60)
                        .posterShadow()
                        .padding(.vertical, 8)

                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.displayTitle)
                                    .font(posterType == .landscape ? .subheadline : .callout)
                                    .fontWeight(.regular)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                accessoryView
                                    .font(.caption)
                                    .foregroundColor(Color(UIColor.lightGray))
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .onSizeChanged { newSize in
                            contentWidth = newSize.width
                        }
                    }
                }

                Color.secondarySystemFill
                    .frame(width: contentWidth, height: 1)
            }
            .edgePadding(.horizontal)
        }
    }
}

extension PagingLibraryView.LibraryRow {

    init(item: Element, posterType: PosterType) {
        self.init(
            item: item,
            onSelect: {},
            posterType: posterType
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
