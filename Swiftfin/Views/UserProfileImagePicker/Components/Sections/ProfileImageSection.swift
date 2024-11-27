//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

extension UserProfileImagePicker {

    struct ProfileImageSection: View {

        @Default(.accentColor)
        private var accentColor

        @State
        var imageSource: ImageSource
        let username: String
        let onSelect: () -> Void?

        @ViewBuilder
        private var imageView: some View {
            RedrawOnNotificationView(name: .init("didChangeUserProfileImage")) {
                ImageView(imageSource)
                    .pipeline(.Swiftfin.branding)
                    .image { image in
                        image.posterBorder(ratio: 1 / 2, of: \.width)
                    }
                    .placeholder { _ in
                        SystemImageContentView(systemName: "person.fill", ratio: 0.5)
                    }
                    .failure {
                        SystemImageContentView(systemName: "person.fill", ratio: 0.5)
                    }
            }
        }

        @ViewBuilder
        var body: some View {
            Section {
                VStack(alignment: .center) {
                    Button {
                        onSelect()
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            // `.aspectRatio(contentMode: .fill)` on `imageView` alone
                            // causes a crash on some iOS versions
                            ZStack {
                                imageView
                            }
                            .aspectRatio(1, contentMode: .fill)
                            .clipShape(.circle)
                            .frame(width: 150, height: 150)
                            .shadow(radius: 5)

                            Image(systemName: "pencil.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .shadow(radius: 10)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(accentColor.overlayColor, accentColor)
                        }
                    }

                    Text(username)
                        .fontWeight(.semibold)
                        .font(.title2)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
    }
}
