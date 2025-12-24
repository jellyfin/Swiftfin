//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct VersionMenu: View {

        let mediaSources: [MediaSourceInfo]
        let selection: Binding<MediaSourceInfo?>

        // MARK: - Body

        var body: some View {
            Menu(L10n.version, systemImage: "list.dash") {
                Picker(L10n.version, selection: selection) {
                    ForEach(mediaSources, id: \.hashValue) { mediaSource in
                        Button {
                            Text(mediaSource.displayTitle)
                        }
                        .tag(mediaSource as MediaSourceInfo?)
                    }
                }
            }
        }
    }
}
