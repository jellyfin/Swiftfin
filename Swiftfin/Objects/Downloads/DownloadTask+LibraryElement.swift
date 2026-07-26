//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

private let downloadTaskListLandscapeWidth: CGFloat = 110
private let downloadTaskListPortraitWidth: CGFloat = 60

extension DownloadTask: LibraryElement {

    var supportedLibraryStyleOptions: LibraryStyleOptions {
        item.supportedLibraryStyleOptions
    }

    func libraryDidSelectElement(
        router: Router.Wrapper,
        in namespace: Namespace.ID
    ) {
        item.libraryDidSelectElement(router: router, in: namespace)
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

    @Router
    private var router

    let task: DownloadTask
    let libraryStyle: LibraryStyle

    private var resolvedLibraryStyle: LibraryStyle {
        task.resolvedLibraryStyle(libraryStyle)
    }

    var body: some View {
        PosterButton(
            item: task,
            displayType: resolvedLibraryStyle.posterDisplayType
        ) { namespace in
            task.libraryDidSelectElement(router: router, in: namespace)
        }
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
                size: .extraSmall
            )
            .subtleShadow()
            .frame(
                width: resolvedLibraryStyle.posterDisplayType == .landscape ?
                    downloadTaskListLandscapeWidth : downloadTaskListPortraitWidth
            )
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
    }

    @ViewBuilder
    private var accessoryView: some View {
        DotHStack {
            if task.item.type == .episode, let seasonEpisodeLabel = task.item.seasonEpisodeLabel {
                Text(seasonEpisodeLabel)
            } else if let premiereYear = task.item.premiereDateYear {
                Text(premiereYear)
            }

            if let runtime = task.item.runtime {
                Text(runtime, format: .runtime)
            }

            if let officialRating = task.item.officialRating {
                Text(officialRating)
            }
        }
    }
}
