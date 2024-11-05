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

extension MetadataTextEditorView {
    struct MediaFormatSection: View {
        @Binding
        var item: BaseItemDto

        let itemType: BaseItemKind

        var body: some View {
            switch itemType {
            case .movie, .episode:
                videoFormatView
            default:
                EmptyView()
            }
        }

        @ViewBuilder
        private var videoFormatView: some View {
            Section(L10n.format) {
                TextField(L10n.originalAspectRatio, text: Binding(get: {
                    item.aspectRatio ?? ""
                }, set: {
                    item.aspectRatio = $0
                }))

                Video3DFormatPicker(title: L10n.format3D, selectedFormat: Binding(get: {
                    item.video3DFormat
                }, set: {
                    item.video3DFormat = $0
                }))
            }
        }
    }
}
