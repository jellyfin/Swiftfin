//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

/// The orientations that can be applied to a section of posters.
///
/// `square` is intentionally excluded: the items shown in these sections don't
/// provide square images and would fall back to placeholders.
private let posterOrientations: [PosterDisplayType] = [.portrait, .landscape]

extension CustomizeViewsSettings {

    struct PosterOrientationSection: View {

        @Default(.Customization.resumePosterType)
        private var resumePosterType
        @Default(.Customization.nextUpPosterType)
        private var nextUpPosterType
        @Default(.Customization.recentlyAddedPosterType)
        private var recentlyAddedPosterType
        @Default(.Customization.recentlyPlayedPosterType)
        private var recentlyPlayedPosterType
        @Default(.Customization.latestInLibraryPosterType)
        private var latestInLibraryPosterType

        var body: some View {
            Form(systemImage: "rectangle.portrait.on.rectangle.portrait") {
                Section {
                    #if os(iOS)
                    OrientationPicker(L10n.continue, selection: $resumePosterType)
                    #endif

                    OrientationPicker(L10n.nextUp, selection: $nextUpPosterType)

                    #if os(iOS)
                    OrientationPicker(L10n.recentlyAdded, selection: $recentlyAddedPosterType)
                    #endif

                    OrientationPicker(L10n.recentlyPlayed, selection: $recentlyPlayedPosterType)

                    OrientationPicker(
                        L10n.latestWithString(L10n.library.localizedLowercase),
                        selection: $latestInLibraryPosterType
                    )
                } header: {
                    Text(L10n.home)
                } footer: {
                    Text(L10n.posterOrientationDescription)
                }
            }
            .navigationTitle(L10n.orientation)
        }
    }
}

private struct OrientationPicker: View {

    private let title: String

    @Binding
    private var selection: PosterDisplayType

    init(_ title: String, selection: Binding<PosterDisplayType>) {
        self.title = title
        self._selection = selection
    }

    @ViewBuilder
    private var picker: some View {
        Picker(title, selection: $selection) {
            ForEach(posterOrientations, id: \.self) { orientation in
                Label(orientation.displayTitle, systemImage: orientation.systemImage)
                    .tag(orientation)
            }
        }
    }

    var body: some View {
        #if os(tvOS)
        ListRowMenu(title) {
            Text(selection.displayTitle)
        } content: {
            picker
        }
        #else
        picker
        #endif
    }
}
