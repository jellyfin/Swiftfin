//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

extension IdentifyItemView {

    struct RemoteSearchResultButton: View {

        // MARK: - Remote Search Result Variable

        let remoteSearchResult: RemoteSearchResult
        let remoteImage: any View

        // MARK: - Remote Search Result Action

        let onSelect: () -> Void

        // MARK: - Result Title

        private var resultTitle: String {
            let name = remoteSearchResult.name ?? L10n.unknown
            let year = remoteSearchResult.productionYear?.description ?? .emptyDash

            return "\(name) (\(year))"
        }

        // MARK: - Body

        var body: some View {
            Button(action: onSelect) {
                HStack {
                    remoteImage
                        .eraseToAnyView()
                        .frame(width: 30, height: 90)
                        .padding(.horizontal)

                    VStack(alignment: .leading) {
                        Text(
                            resultTitle
                        )
                        .font(.headline)
                        .foregroundStyle(Color.primary)

                        HStack {
                            Text(remoteSearchResult.overview ?? L10n.unknown)
                                .lineLimit(3)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
        }
    }
}
