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
        let image: UIImage

        // MARK: - Image Functions

        let onDelete: () -> Void

        // MARK: - Header

        @ViewBuilder
        private var header: some View {
            Section {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
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
                    TextPairView(leading: L10n.type, trailing: index.description)
                }

                if let imageTag = imageInfo.imageTag {
                    TextPairView(leading: L10n.tag, trailing: imageTag)
                }

                if let imageType = imageInfo.imageType {
                    TextPairView(leading: L10n.type, trailing: imageType.rawValue)
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

        var deleteButton: some View {
            ListRowButton(L10n.delete) {
                onDelete()
            }
            .foregroundStyle(
                accentColor.overlayColor,
                .red
            )
        }

        var body: some View {
            List {
                header
                details
                deleteButton
            }
        }
    }
}
