//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct MediaStreamInfoView: View {

    private let mediaStream: MediaStream?

    init(mediaStream: MediaStream?) {
        self.mediaStream = mediaStream
    }

    var body: some View {
        Form {
            if let mediaStream {
                Section(L10n.details) {
                    ForEach(mediaStream.metadataProperties, id: \.label) { property in
                        LabeledContent(property.label, value: property.value)
                    }
                }

                if mediaStream.colorProperties.isNotEmpty {
                    Section(L10n.color) {
                        ForEach(mediaStream.colorProperties, id: \.label) { property in
                            LabeledContent(property.label, value: property.value)
                        }
                    }
                }

                if mediaStream.deliveryProperties.isNotEmpty {
                    Section(L10n.delivery) {
                        ForEach(mediaStream.deliveryProperties, id: \.label) { property in
                            LabeledContent(property.label, value: property.value)
                        }
                    }
                }
            } else {
                Section(L10n.details) {
                    Text(L10n.none)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .labeledContentStyle(.focusable)
        #if os(iOS)
            // tvOS shares this view with another so this title updates with focus and overrides that title
                .navigationTitle(mediaStream?.displayTitle ?? .emptyDash)
                .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
