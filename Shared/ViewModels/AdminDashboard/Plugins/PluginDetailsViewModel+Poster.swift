//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension PluginDetailsViewModel: @preconcurrency Poster {

    nonisolated static func == (lhs: PluginDetailsViewModel, rhs: PluginDetailsViewModel) -> Bool {
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    var displayTitle: String {
        plugin.displayTitle
    }

    var preferredPosterDisplayType: PosterDisplayType {
        .landscape
    }

    var systemImage: String {
        "puzzlepiece.extension"
    }

    func imageSources(
        for displayType: PosterDisplayType,
        environment: Empty
    ) -> [ImageSource] {
        switch plugin.isInstalled {
        case true:
            if plugin.hasImage == true, let id = plugin.id, let version = plugin.version {
                ImageSource(url: userSession?.client.url(with: Paths.getPluginImage(pluginID: id, version: version)))
            }

        case false:
            ImageSource(url: URL(string: package?.imageURL))
        }
    }
}

extension PluginDetailsViewModel: LibraryElement {

    func makeBody(
        libraryStyle: LibraryStyle,
        action: (() -> Void)?
    ) -> some View {
        PluginLibraryListElement(
            viewModel: self,
            action: action
        )
    }
}

private struct PluginLibraryListElement: View {

    @ObservedObject
    var viewModel: PluginDetailsViewModel
    var action: (() -> Void)?

    var body: some View {
        ListRow {
            PosterImage(
                item: viewModel,
                type: .landscape,
                size: .extraSmall
            )
            .pipeline(.Swiftfin.other)
            .subtleShadow()
            .frame(width: 110, height: 110 / 1.77)
        } content: {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.plugin.displayTitle)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Group {
                    if viewModel.plugin.isInstalled {
                        if let version = viewModel.plugin.version {
                            LabeledContent(L10n.version) {
                                Text(version)
                            }
                            .monospacedDigit()
                        }

                        if let status = viewModel.plugin.status {
                            LabeledContent(L10n.status) {
                                Text(status.displayTitle)
                            }
                        }
                    } else if let description = viewModel.plugin.description {
                        Text(description)
                            .lineLimit(2)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        } action: {
            action?()
        }
    }
}
