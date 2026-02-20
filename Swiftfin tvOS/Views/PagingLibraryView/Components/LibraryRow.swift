//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

private let landscapeMaxWidth: CGFloat = 110
private let portraitMaxWidth: CGFloat = 60

extension PagingLibraryView {

    struct LibraryRow: View {

        private let item: Element
        private var action: () -> Void
        private let posterType: PosterDisplayType

        init(
            item: Element,
            posterType: PosterDisplayType,
            action: @escaping () -> Void
        ) {
            self.item = item
            self.action = action
            self.posterType = posterType
        }

        private func imageSources(from element: Element) -> [ImageSource] {
            switch posterType {
            case .landscape:
                element.landscapeImageSources(maxWidth: landscapeMaxWidth, quality: 90)
            case .portrait:
                element.portraitImageSources(maxWidth: portraitMaxWidth, quality: 90)
            case .square:
                element.squareImageSources(maxWidth: portraitMaxWidth, quality: 90)
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

        @ViewBuilder
        private var rowContent: some View {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.displayTitle)
                        .font(posterType == .landscape ? .subheadline : .callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    accessoryView
                        .font(.caption)
                        .foregroundColor(Color(UIColor.lightGray))
                }
                Spacer()
            }
        }

        @ViewBuilder
        private var rowLeading: some View {
            ZStack {
                Color.clear

                ImageView(imageSources(from: item))
                    .failure {
                        SystemImageContentView(systemName: item.systemImage)
                    }
            }
            .posterStyle(posterType)
            .frame(width: posterType == .landscape ? 110 : 60)
            .posterShadow()
            .padding(.vertical, 8)
        }

        // MARK: body

        var body: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                rowLeading
            } content: {
                rowContent
            }
            .onSelect(perform: action)
            .focusedValue(\.focusedPoster, AnyPoster(item))
        }
    }
}
