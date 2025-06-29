//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Nuke
import SwiftUI

struct UserProfileImage<Placeholder: View>: View {

    // MARK: - Environment Variables

    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isEditing)
    private var isEditing
    @Environment(\.isSelected)
    private var isSelected

    // MARK: - User Variables

    private let userID: String?
    private let source: ImageSource
    private let pipeline: ImagePipeline
    private let placeholder: Placeholder

    // MARK: - Overlay Opacity

    private var overlayOpacity: Double {
        /// Dim the Profile Image if Editing & Unselected or if Disabled
        if (isEditing && !isSelected) || !isEnabled {
            return 0.5
        } else {
            return 0.0
        }
    }

    // MARK: - Body

    var body: some View {
        RedrawOnNotificationView(
            .didChangeUserProfile,
            filter: {
                $0 == userID
            }
        ) {
            ImageView(source)
                .pipeline(pipeline)
                .image {
                    $0.posterBorder()
                        .containerShape(.circle)
                }
                .placeholder { _ in
                    placeholder
                }
                .failure {
                    placeholder
                }
                .overlay {
                    Color.black
                        .opacity(overlayOpacity)
                }
                .aspectRatio(1, contentMode: .fill)
                .clipShape(.circle)
                .shadow(radius: 5)
        }
    }
}

// MARK: - Initializer

extension UserProfileImage {

    init(
        userID: String?,
        source: ImageSource,
        pipeline: ImagePipeline = .Swiftfin.posters,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.userID = userID
        self.source = source
        self.pipeline = pipeline
        self.placeholder = placeholder()
    }
}

extension UserProfileImage where Placeholder == SystemImageContentView {

    init(
        userID: String?,
        source: ImageSource,
        pipeline: ImagePipeline = .Swiftfin.posters
    ) {
        self.userID = userID
        self.source = source
        self.pipeline = pipeline
        self.placeholder = SystemImageContentView(systemName: "person.fill", ratio: 0.5)
    }
}
