//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: consolidate width constants

private let baseItemListLandscapeWidth: CGFloat = 110
private let baseItemListPortraitWidth: CGFloat = 60

extension BaseItemDto: LibraryElement {

    var supportedLibraryStyleOptions: LibraryStyleOptions {
        switch type {
        case .collectionFolder, .folder, .userView:
            return BaseItemKind.libraryStyleOptions(for: supportedItemTypes)
        default:
            break
        }

        return type.map { BaseItemKind.libraryStyleOptions(for: [$0]) } ?? .default
    }

    func libraryDidSelectElement(
        router: Router.Wrapper,
        in namespace: Namespace.ID
    ) {
        switch type {
        case .collectionFolder, .folder, .userView:
            router.route(
                to: .library(library: ItemLibrary(parent: self, filters: .default)),
                in: namespace
            )

        default:
            router.route(to: .item(item: self), in: namespace)
        }
    }

    @ViewBuilder
    func makeBody(
        libraryStyle: LibraryStyle,
        action: (() -> Void)?
    ) -> some View {
        switch libraryStyle.displayType {
        case .grid:
            BaseItemDtoLibraryGridElement(item: self, libraryStyle: libraryStyle, action: action)
        case .list:
            BaseItemDtoLibraryListElement(item: self, libraryStyle: libraryStyle, action: action)
        }
    }
}

private struct BaseItemDtoLibraryGridElement: View {

    @Router
    private var router

    @Environment(\.isEditing)
    private var isEditing

    @SharedBaseItem
    var item: BaseItemDto
    let libraryStyle: LibraryStyle
    let action: (() -> Void)?

    private var resolvedLibraryStyle: LibraryStyle {
        item.resolvedLibraryStyle(libraryStyle)
    }

    var body: some View {
        PosterButton(
            item: item,
            displayType: resolvedLibraryStyle.posterDisplayType
        ) { namespace in
            if isEditing {
                action?()
            } else {
                item.libraryDidSelectElement(router: router, in: namespace)
            }
        }
    }
}

private struct BaseItemDtoLibraryListElement: View {

    @Namespace
    private var namespace

    @Router
    private var router

    @Environment(\.isEditing)
    private var isEditing
    @Environment(\.isSelected)
    private var isSelected

    @SharedBaseItem
    var item: BaseItemDto
    let libraryStyle: LibraryStyle
    let action: (() -> Void)?

    private var resolvedLibraryStyle: LibraryStyle {
        item.resolvedLibraryStyle(libraryStyle)
    }

    var body: some View {
        ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
            PosterImage(
                item: item,
                type: resolvedLibraryStyle.posterDisplayType,
                size: .extraSmall
            )
            .subtleShadow()
            .frame(width: resolvedLibraryStyle.posterDisplayType == .landscape ? baseItemListLandscapeWidth : baseItemListPortraitWidth)
            .overlay {
                Color.black
                    .opacity(isEditing && !isSelected ? 0.5 : 0.0)
            }
        } content: {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.displayTitle)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            isEditing ? (isSelected ? .primary : .secondary) : .primary
                        )
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let program = item.currentProgram {
                        currentProgramView(program)
                    } else if item.type == .program {
                        currentProgramView(item)
                    } else {
                        accessoryView
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ListRowCheckbox()
            }
        } action: {
            if isEditing {
                action?()
            } else {
                item.libraryDidSelectElement(router: router, in: namespace)
            }
        }
        #if os(tvOS)
        .focusedValue(\.focusedPoster, AnyPoster(item))
        #else
            .matchedTransitionSource(id: "item", in: namespace)
        #endif
    }

    @ViewBuilder
    private func currentProgramView(_ program: BaseItemDto) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if program.id != item.id {
                Text(program.displayTitle)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            if let progress = program.progressPercentage {
                ProgressView(value: progress)
                    .progressViewStyle(.playback)
                    .frame(height: 4)
                    .foregroundStyle(Color.accentColor)
            }

            if let start = program.startDate, let end = program.endDate {
                DotHStack {
                    if !Calendar.current.isDateInToday(start) {
                        Text(start, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    }

                    Text(start, style: .time)
                    Text(end, style: .time)

                    if program.isRecording && program.isAiring {
                        Text(L10n.recording)
                            .foregroundStyle(.red)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var accessoryView: some View {
        DotHStack {
            if item.type == .episode, let seasonEpisodeLocator = item.seasonEpisodeLabel {
                Text(seasonEpisodeLocator)
            } else if let premiereYear = item.premiereDateYear {
                Text(premiereYear)
            }

            if let runtime = item.runtime {
                Text(runtime, format: .runtime)
            }

            if let officialRating = item.officialRating {
                Text(officialRating)
            }
        }
    }
}
