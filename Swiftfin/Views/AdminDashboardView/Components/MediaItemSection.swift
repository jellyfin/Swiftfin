//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AdminDashboardView {

    struct MediaItemSection: View {

        let item: BaseItemDto

        var body: some View {
            Section {
                HStack(alignment: .bottom, spacing: 12) {
                    Group {
                        if item.type == .audio {
                            ZStack {
                                Color.clear

                                ImageView(item.squareImageSources(maxWidth: 60))
                                    .failure {
                                        SystemImageContentView(systemName: item.systemImage)
                                    }
                            }
                            .squarePosterStyle()
                        } else {
                            ZStack {
                                Color.clear

                                ImageView(item.portraitImageSources(maxWidth: 60))
                                    .failure {
                                        SystemImageContentView(systemName: item.systemImage)
                                    }
                            }
                            .posterStyle(.portrait)
                        }
                    }
                    .frame(width: 100)
                    .accessibilityIgnoresInvertColors()

                    VStack(alignment: .leading) {

                        if let parent = item.parentTitle {
                            Text(parent)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Text(item.displayTitle)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .listRowBackground(Color.clear)
            .listRowCornerRadius(0)
            .listRowInsets(.zero)
        }
    }
}
