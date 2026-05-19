//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import Nuke
import SwiftUI

struct UserProfileHeroImage: View {

    @Default(.accentColor)
    private var accentColor

    @Injected(\.currentUserSession)
    private var userSession

    @State
    private var isPresentingOptions: Bool = false

    let user: UserDto
    let source: ImageSource
    var pipeline: ImagePipeline = .Swiftfin.posters
    let onUpdate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Section {
            VStack(alignment: .center) {
                Button {
                    isPresentingOptions = true
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        UserProfileImage(
                            userID: user.id,
                            source: source,
                            pipeline: userSession?.user.id == user.id ? .Swiftfin.local : .Swiftfin.posters
                        )
                        .frame(width: 150, height: 150)

                        Image(systemName: "pencil.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .shadow(radius: 10)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(accentColor.overlayColor, accentColor)
                    }
                }

                Text(user.name ?? L10n.unknown)
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
            Button(L10n.selectImage, action: onUpdate)

            Button(L10n.delete, role: .destructive, action: onDelete)
        }
    }
}
