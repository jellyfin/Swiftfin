//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension PluginsView {

    struct PluginRow: View {

        @ObservedObject
        var viewModel: PluginDetailsViewModel

        @Router
        private var router

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
                                LabeledContent(L10n.version, value: version)
                                    .monospacedDigit()
                            }

                            if let status = viewModel.plugin.status {
                                LabeledContent(L10n.status, value: status.displayTitle)
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
                router.route(to: .pluginDetails(viewModel: viewModel))
            }
        }
    }
}
