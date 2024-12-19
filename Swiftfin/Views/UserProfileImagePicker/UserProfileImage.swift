//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct UserProfileImage: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - User Profile Variables

    let username: String?
    let imageSource: ImageSource

    // MARK: - User Profile Action Menu

    let select: () -> Void
    let delete: () -> Void

    // MARK: - Dialog State

    @State
    private var isPresentingOptions = false

    // MARK: - Image View

    @ViewBuilder
    private var imageView: some View {
        RedrawOnNotificationView(.didChangeUserProfile) {
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

    // MARK: - Body

    var body: some View {
        Section {
            VStack(alignment: .center) {
                Button {
                    isPresentingOptions = true
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

                Text(username ?? L10n.unknown)
                    .fontWeight(.semibold)
                    .font(.title2)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
        .confirmationDialog(
            L10n.profileImage,
            isPresented: $isPresentingOptions,
            titleVisibility: .visible
        ) {
            Button(L10n.selectImage) {
                select()
            }
            Button(L10n.delete, role: .destructive) {
                delete()
            }
        }
    }
}
