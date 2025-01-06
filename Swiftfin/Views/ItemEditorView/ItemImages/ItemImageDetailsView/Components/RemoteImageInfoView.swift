//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemImageDetailsView {
    struct RemoteImageInfoView: View {

        // MARK: - Image Info

        let imageInfo: RemoteImageInfo

        // MARK: - Image Functions

        let onSave: () -> Void

        // MARK: - Header

        @ViewBuilder
        private var header: some View {
            Section {
                ImageView(URL(string: imageInfo.url))
                    .placeholder { _ in
                        Image(systemName: imageInfo.systemImage)
                    }
                    .failure {
                        Image(systemName: imageInfo.systemImage)
                    }
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .posterStyle(imageInfo.height ?? 0 > imageInfo.width ?? 0 ? .portrait : .landscape)
                    .accessibilityIgnoresInvertColors()
            }
            .listRowBackground(Color.clear)
            .listRowCornerRadius(0)
            .listRowInsets(.zero)
        }

        // MARK: - Details

        @ViewBuilder
        private var details: some View {
            Section(L10n.details) {

                if let providerName = imageInfo.providerName {
                    TextPairView(leading: L10n.provider, trailing: providerName)
                }

                TextPairView(leading: L10n.id, trailing: imageInfo.id.description)

                if let communityRating = imageInfo.communityRating {
                    TextPairView(leading: L10n.rating, trailing: communityRating.description)
                }

                if let voteCount = imageInfo.voteCount {
                    TextPairView(leading: "Votes", trailing: voteCount.description)
                }

                if let language = imageInfo.language {
                    TextPairView(leading: L10n.language, trailing: language)
                }

                if let width = imageInfo.width, let height = imageInfo.height {
                    TextPairView(leading: "Dimensions", trailing: "\(width) x \(height)")
                }

                if let url = imageInfo.url {
                    TextPairView(leading: L10n.url, trailing: url)
                        .onSubmit {
                            UIApplication.shared.open(URL(string: url)!)
                        }
                }
            }
        }

        // MARK: - Body

        var body: some View {
            List {
                header
                details
            }
            .topBarTrailing {
                Button(L10n.save, action: onSave)
                    .buttonStyle(.toolbarPill)
            }
        }
    }
}
