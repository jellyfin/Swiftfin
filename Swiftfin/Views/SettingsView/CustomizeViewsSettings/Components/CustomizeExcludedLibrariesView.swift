//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CustomizeExcludedLibrariesView: View {
    @Default(.Customization.Library.excludeLibraries)
    private var excludedLibraries

    @StateObject
    private var viewModel = MediaViewModel()

    @State
    private var allLibraries: [ExcludedLibrary] = []

    var body: some View {
        OrderedSectionSelectorView(
            selection: $excludedLibraries,
            sources: allLibraries,
            enabledTitle: "Disabled Libraries",
            disabledTitle: "Enabled Libraries"
        )
        .navigationTitle(L10n.library)
        .task {
            allLibraries = await viewModel.sourceLibraries()
        }
    }
}
