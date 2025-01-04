//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

extension EditMetadataView {

    struct MediaFormatSection: View {

        @Binding
        var item: BaseItemDto

        var body: some View {
            Section(L10n.format) {
                TextField(
                    L10n.originalAspectRatio,
                    value: $item.aspectRatio,
                    format: .nilIfEmptyString
                )

                Video3DFormatPicker(
                    title: L10n.format3D,
                    selectedFormat: $item.video3DFormat
                )
            }
        }
    }
}
