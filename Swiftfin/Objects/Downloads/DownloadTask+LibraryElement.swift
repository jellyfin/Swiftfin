//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension DownloadTask: LibraryElement {

    var supportedLibraryStyleOptions: LibraryStyleOptions {
        item.supportedLibraryStyleOptions
    }

    func libraryDidSelectElement(
        router: Router.Wrapper,
        in namespace: Namespace.ID
    ) {
        // TODO: route downloaded items to the item view
        // router.route(to: .item(item: item), in: namespace)
    }

    @ViewBuilder
    func makeBody(
        libraryStyle: LibraryStyle,
        action: (() -> Void)?
    ) -> some View {
        switch libraryStyle.displayType {
        case .grid:
            DownloadTaskLibraryGridElement(task: self, libraryStyle: libraryStyle)
        case .list:
            DownloadTaskLibraryListElement(task: self, libraryStyle: libraryStyle)
        }
    }
}

private struct DownloadTaskLibraryGridElement: View {

    @Namespace
    private var namespace

    @Router
    private var router

    let task: DownloadTask
    let libraryStyle: LibraryStyle

    private var resolvedLibraryStyle: LibraryStyle {
        task.resolvedLibraryStyle(libraryStyle)
    }

    var body: some View {
        #if os(iOS)
        PosterButton(
            item: task,
            type: resolvedLibraryStyle.posterDisplayType
        ) { namespace in
            task.libraryDidSelectElement(router: router, in: namespace)
        } label: {
            PosterButton<DownloadTask>.TitleSubtitleContentView(item: task)
        }
        #else
        PosterButton(
            item: task,
            type: resolvedLibraryStyle.posterDisplayType
        ) {
            task.libraryDidSelectElement(router: router, in: namespace)
        } label: {
            PosterButton<DownloadTask>.TitleSubtitleContentView(item: task)
        }
        #endif
    }
}

private struct DownloadTaskLibraryListElement: View {

    @Namespace
    private var namespace

    @Router
    private var router

    let task: DownloadTask
    let libraryStyle: LibraryStyle

    private var resolvedLibraryStyle: LibraryStyle {
        task.resolvedLibraryStyle(libraryStyle)
    }

    var body: some View {
        ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
            PosterImage(
                item: task,
                type: resolvedLibraryStyle.posterDisplayType,
                contentMode: .fill
            )
            .posterShadow()
            .frame(width: resolvedLibraryStyle.posterDisplayType.libraryListWidth)
        } content: {
            VStack(alignment: .leading, spacing: 5) {
                Text(task.displayTitle)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                accessoryView
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } action: {
            task.libraryDidSelectElement(router: router, in: namespace)
        }
        .backport
        .matchedTransitionSource(id: "item", in: namespace)
        #if os(tvOS)
            .focusedValue(\.focusedPoster, AnyPoster(task))
        #endif
    }

    @ViewBuilder
    private var accessoryView: some View {
        DotHStack {
            if let seasonEpisodeLabel = task.seasonEpisodeLabel {
                Text(seasonEpisodeLabel)
            } else if let premiereDateYear = task.premiereDateYear {
                Text(premiereDateYear)
            }

            if let runTimeLabel = task.runTimeLabel {
                Text(runTimeLabel)
            }

            if let officialRating = task.officialRating {
                Text(officialRating)
            }
        }
    }
}
