//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension PagingLibraryView {

    struct LibraryRow: View {

        @State
        private var contentWidth: CGFloat = 0
        @State
        private var focusedItem: Element?

        @FocusState
        private var isFocused: Bool

        private let item: Element
        private var action: () -> Void
        private var contextMenu: () -> any View
        private let posterType: PosterDisplayType

        private var onFocusChanged: ((Bool) -> Void)?

        private func imageView(from element: Element) -> ImageView {
            switch posterType {
            case .landscape:
                ImageView(element.landscapeImageSources(maxWidth: 110))
            case .portrait:
                ImageView(element.portraitImageSources(maxWidth: 60))
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

                imageView(from: item)
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
            .contextMenu(menuItems: {
                contextMenu()
                    .eraseToAnyView()
            })
            .posterShadow()
            .ifLet(onFocusChanged) { view, onFocusChanged in
                view
                    .focused($isFocused)
                    .onChange(of: isFocused) { _, newValue in
                        onFocusChanged(newValue)
                    }
            }
        }
    }
}

extension PagingLibraryView.LibraryRow {

    init(item: Element, posterType: PosterDisplayType) {
        self.init(
            item: item,
            action: {},
            contextMenu: { EmptyView() },
            posterType: posterType,
            onFocusChanged: nil
        )
    }
}

extension PagingLibraryView.LibraryRow {

    func onSelect(perform action: @escaping () -> Void) -> Self {
        copy(modifying: \.action, with: action)
    }

    func contextMenu(@ViewBuilder perform content: @escaping () -> any View) -> Self {
        copy(modifying: \.contextMenu, with: content)
    }

    func onFocusChanged(perform action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onFocusChanged, with: action)
    }
}
