//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

private let channelProgramListWidth: CGFloat = 60

extension ChannelProgram: LibraryElement {

    static var supportedLibraryStyleOptions: LibraryStyleOptions {
        BaseItemKind.libraryStyleOptions(for: [.tvChannel])
    }

    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID) {
        router.route(to: .item(item: channel), in: namespace)
    }

    @ViewBuilder
    func makeBody(
        libraryStyle: LibraryStyle,
        action: (() -> Void)?
    ) -> some View {
        switch libraryStyle.displayType {
        case .grid:
            ChannelProgramLibraryGridElement(channelProgram: self, libraryStyle: libraryStyle)
        case .list:
            ChannelProgramLibraryListElement(channelProgram: self, libraryStyle: libraryStyle)
        }
    }
}

private struct ChannelProgramLibraryGridElement: View {

    @Namespace
    private var namespace

    @Router
    private var router

    let channelProgram: ChannelProgram
    let libraryStyle: LibraryStyle

    private var resolvedLibraryStyle: LibraryStyle {
        channelProgram.resolvedLibraryStyle(libraryStyle)
    }

    var body: some View {
        Button {
            channelProgram.libraryDidSelectElement(router: router, in: namespace)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                PosterImage(item: channelProgram, type: resolvedLibraryStyle.posterDisplayType)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .posterStyle(resolvedLibraryStyle.posterDisplayType)
                    .backport
                    .matchedTransitionSource(id: "item", in: namespace)
                    .posterShadow()

                if channelProgram.showTitle || channelProgram.subtitle != nil {
                    VStack(alignment: .leading, spacing: 0) {
                        if channelProgram.showTitle {
                            Text(channelProgram.displayTitle)
                                .font(.footnote)
                                .foregroundStyle(.primary)
                                .lineLimit(1, reservesSpace: true)
                        }

                        Text(channelProgram.subtitle ?? " ")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .lineLimit(1, reservesSpace: true)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary, .secondary)
    }
}

private struct ChannelProgramLibraryListElement: View {

    @Namespace
    private var namespace

    @Router
    private var router

    let channelProgram: ChannelProgram
    let libraryStyle: LibraryStyle

    private var resolvedLibraryStyle: LibraryStyle {
        channelProgram.resolvedLibraryStyle(libraryStyle)
    }

    var body: some View {
        ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
            PosterImage(item: channelProgram, type: resolvedLibraryStyle.posterDisplayType)
                .posterStyle(resolvedLibraryStyle.posterDisplayType)
                .frame(width: channelProgramListWidth)
                .backport
                .matchedTransitionSource(id: "item", in: namespace)
                .posterShadow()
        } content: {
            VStack(alignment: .leading, spacing: 5) {
                Text(channelProgram.displayTitle)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let subtitle = channelProgram.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } action: {
            channelProgram.libraryDidSelectElement(router: router, in: namespace)
        }
    }
}
