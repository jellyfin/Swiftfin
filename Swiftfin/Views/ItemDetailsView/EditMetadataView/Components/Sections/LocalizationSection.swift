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

extension EditMetadataView {
    struct LocalizationSection: View {
        @Binding
        var item: BaseItemDto

        var body: some View {
            Section(L10n.metadataPreferences) {
                LanguagePicker(title: L10n.language, selectedLanguageCode: Binding(get: {
                    item.preferredMetadataLanguage
                }, set: {
                    item.preferredMetadataLanguage = $0
                }))

                CountryPicker(title: L10n.country, selectedCountryCode: Binding(get: {
                    item.preferredMetadataCountryCode
                }, set: {
                    item.preferredMetadataCountryCode = $0
                }))
            }
        }
    }
}
