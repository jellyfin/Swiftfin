//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ItemImageDetailsView {
    struct LocalImageInfoView: View {

        // MARK: - Defaults

        @Default(.accentColor)
        private var accentColor

        // MARK: - Image Info

        let imageInfo: ImageInfo
        let imageURL: URL

        // MARK: - Image Functions

        let onDelete: () -> Void

        // MARK: - Header

        @ViewBuilder
        private var header: some View {
            Section {
                ImageView(imageURL)
                    .placeholder { _ in
                        Image(systemName: "circle")
                    }
                    .failure {
                        Image(systemName: "circle")
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

                TextPairView(leading: L10n.id, trailing: imageInfo.id.description)

                if let index = imageInfo.imageIndex {
                    TextPairView(leading: "Index", trailing: index.description)
                }

                if let imageTag = imageInfo.imageTag {
                    TextPairView(leading: L10n.tag, trailing: imageTag)
                }

                if let width = imageInfo.width, let height = imageInfo.height {
                    TextPairView(leading: "Dimensions", trailing: "\(width) x \(height)")
                }

                if let path = imageInfo.path {
                    TextPairView(leading: "Path", trailing: path)
                        .onSubmit {
                            UIApplication.shared.open(URL(string: path)!)
                        }
                }
            }
        }

        // MARK: - Delete Button

        var deleteButton: some View {
            ListRowButton(L10n.delete) {
                onDelete()
            }
            .foregroundStyle(
                accentColor.overlayColor,
                .red
            )
        }

        // MARK: - Body

        var body: some View {
            List {
                header
                details
                deleteButton
            }
        }
    }
}
