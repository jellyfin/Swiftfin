//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct Description: View {

        @Router
        private var router

        let item: BaseItemDto

        private var isPresented: Bool {
            item.taglines?.contains(where: \.isNotEmpty) == true ||
                item.overview?.isNotEmpty == true
        }

        var body: some View {
            if isPresented {
                VStack(alignment: .leading, spacing: 5) {
                    if let firstTagline = item.taglines?.first(where: \.isNotEmpty) {
                        Text(firstTagline)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }

                    if let itemOverview = item.overview, itemOverview.isNotEmpty {
                        InlinePlatformView {
                            Button {
                                router.route(to: .itemOverview(item: item))
                            } label: {
                                SeeMoreText(itemOverview)
                                    .font(.footnote)
                                    .lineLimit(3)
                            }
                            .buttonStyle(.plain)
                        } tvOSView: {
                            Text(itemOverview)
                                .font(.footnote)
                                .lineLimit(3)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
