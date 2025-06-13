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

    struct LocalizationSection: View {

        @Binding
        var item: BaseItemDto

        var body: some View {
            Section(L10n.metadataPreferences) {
                CulturePicker(
                    L10n.language,
                    twoLetterISOLanguageName: $item.preferredMetadataLanguage
                )

                CountryPicker(
                    L10n.country,
                    twoLetterISORegion: $item.preferredMetadataCountryCode
                )
            }
        }
    }
}
