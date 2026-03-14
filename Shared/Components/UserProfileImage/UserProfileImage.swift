//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Nuke
import SwiftUI

struct UserProfileImage: View {

    @Environment(\.isEditing)
    private var isEditing
    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isSelected)
    private var isSelected

    private let userID: String?
    private let source: ImageSource
    private let pipeline: ImagePipeline

    init(
        userID: String?,
        source: ImageSource,
        pipeline: ImagePipeline = .Swiftfin.posters
    ) {
        self.userID = userID
        self.source = source
        self.pipeline = pipeline
    }

    private var overlayOpacity: Double {
        /// Dim the Profile Image if Editing & Unselected or if Disabled
        if (isEditing && !isSelected) || !isEnabled {
            0.5
        } else {
            0.0
        }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.complexSecondary)

            RedrawOnNotificationView(
                .didChangeUserProfile,
                filter: {
                    $0 == userID
                }
            ) {
                AlternateLayoutView {
                    Color.clear
                } content: {
                    ImageView(source)
                        .pipeline(pipeline)
                        .image { image in
                            image.aspectRatio(contentMode: .fill)
                        }
                        .placeholder { _ in
                            SystemImageContentView(
                                systemName: "person.fill",
                                ratio: 0.5
                            )
                        }
                        .failure {
                            SystemImageContentView(
                                systemName: "person.fill",
                                ratio: 0.5
                            )
                        }
                        .overlay {
                            Color.black
                                .opacity(overlayOpacity)
                        }
                }
            }
        }
        .posterBorder()
        .containerShape(.circle)
        .clipShape(.circle)
        .aspectRatio(1, contentMode: .fit)
        .shadow(radius: 5)
    }
}
