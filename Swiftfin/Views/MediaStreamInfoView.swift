//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct MediaStreamInfoView: View {

    let mediaStream: MediaStream

    var body: some View {
        Form {
            Section(mediaStream.displayTitle ?? .emptyDash) {
                ForEach(mediaStream.metadataProperties) { property in
                    SplitText(leading: property.displayTitle, trailing: property.value)
                }
            }

            if !mediaStream.colorProperties.isEmpty {
                Section("Color") {
                    ForEach(mediaStream.colorProperties) { property in
                        SplitText(leading: property.displayTitle, trailing: property.value)
                    }
                }
            }

            if !mediaStream.deliveryProperties.isEmpty {
                Section("Delivery") {
                    ForEach(mediaStream.deliveryProperties) { property in
                        SplitText(leading: property.displayTitle, trailing: property.value)
                    }
                }
            }
        }
    }
}
