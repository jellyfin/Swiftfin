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
            BaseItemDtoLibraryGridElement(item: self, libraryStyle: libraryStyle)
        case .list:
            BaseItemDtoLibraryListElement(item: self, libraryStyle: libraryStyle)
        case .guide:
            BaseItemDtoLibraryGuideElement(item: self)
        }
    }
}

private struct BaseItemDtoLibraryGuideElement: View {

    @Router
    private var router

    @EnvironmentObject
    private var guideViewModel: GuideViewModel

    let item: BaseItemDto

    var body: some View {
        GuideChannelRow(
            programsViewModel: guideViewModel.programsViewModel(for: item),
            scrollProxy: guideViewModel.scrollProxy,
            now: guideViewModel.now,
            baseStart: guideViewModel.baseStart,
            channel: item,
            metrics: .current,
            onSelectChannel: { router.route(to: .item(item: item)) },
            onSelectProgram: { program in router.route(to: .item(item: program)) }
        )
    }
}

private struct BaseItemDtoLibraryGridElement: View {

    @Namespace
    private var namespace

    @Router
    private var router

    let item: BaseItemDto
    let libraryStyle: LibraryStyle

    private var resolvedLibraryStyle: LibraryStyle {
        item.resolvedLibraryStyle(libraryStyle)
    }

    var body: some View {
        #if os(iOS)
        PosterButton(
            item: item,
            type: resolvedLibraryStyle.posterDisplayType
        ) { namespace in
            item.libraryDidSelectElement(router: router, in: namespace)
        } label: {
            PosterButton<BaseItemDto>.TitleSubtitleContentView(item: item)
        }
        #else
        PosterButton(
            item: item,
            type: resolvedLibraryStyle.posterDisplayType
        ) {
            item.libraryDidSelectElement(router: router, in: namespace)
        } label: {
            PosterButton<BaseItemDto>.TitleSubtitleContentView(item: item)
        }
        #endif
    }
}

private struct BaseItemDtoLibraryListElement: View {

    @Namespace
    private var namespace

    @Router
    private var router

    let item: BaseItemDto
    let libraryStyle: LibraryStyle

    private var resolvedLibraryStyle: LibraryStyle {
        item.resolvedLibraryStyle(libraryStyle)
    }

    var body: some View {
        ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
            PosterImage(
                item: item,
                type: resolvedLibraryStyle.posterDisplayType,
                contentMode: .fill
            )
            .posterShadow()
            .frame(width: resolvedLibraryStyle.posterDisplayType == .landscape ? baseItemListLandscapeWidth : baseItemListPortraitWidth)
        } content: {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.displayTitle)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let program = item.currentProgram {
                    currentProgramView(program)
                } else {
                    accessoryView
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } action: {
            item.libraryDidSelectElement(router: router, in: namespace)
        }
        .backport
        .matchedTransitionSource(id: "item", in: namespace)
        #if os(tvOS)
            .focusedValue(\.focusedPoster, AnyPoster(item))
        #endif
    }

    @ViewBuilder
    private func currentProgramView(_ program: BaseItemDto) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(program.displayTitle)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            if let progress = program.programProgress {
                ProgressBar(progress: min(max(progress, 0), 1))
                    .frame(height: 4)
                    .foregroundStyle(Color.accentColor)
            }

            if let start = program.startDate, let end = program.endDate {
                DotHStack {
                    Text(start, style: .time)
                    Text(end, style: .time)
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
