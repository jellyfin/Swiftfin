//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import Nuke
import SwiftUI

struct UserProfileHeroImage: View {

    // MARK: - User Variables

    private let userId: String?
    private let size: CGFloat
    private let source: ImageSource
    private let pipeline: ImagePipeline

    // MARK: - Initializer

    init(
        userId: String?,
        size: CGFloat = 150,
        source: ImageSource,
        pipeline: ImagePipeline = .Swiftfin.default
    ) {
        self.userId = userId
        self.size = size
        self.source = source
        self.pipeline = pipeline
    }

    // MARK: - Body

    var body: some View {
        RedrawOnNotificationView(
            .didChangeUserProfile,
            filter: {
                $0 == userId
            }
        ) {
            ImageView(source)
                .pipeline(pipeline)
                .image {
                    $0.posterBorder(ratio: 1 / 2, of: \.width)
                }
                .placeholder { _ in
                    SystemImageContentView(systemName: "person.fill", ratio: 0.5)
                }
                .failure {
                    SystemImageContentView(systemName: "person.fill", ratio: 0.5)
                }
                .aspectRatio(1, contentMode: .fill)
                .clipShape(Circle())
                .frame(width: size, height: size)
                .shadow(radius: 5)
        }
    }
}
