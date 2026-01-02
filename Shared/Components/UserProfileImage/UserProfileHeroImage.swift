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

    // MARK: - Accent Color

    @Default(.accentColor)
    private var accentColor

    // MARK: - User Session

    @Injected(\.currentUserSession)
    private var userSession

    // MARK: - User Variables

    private let user: UserDto
    private let source: ImageSource
    private let pipeline: ImagePipeline

    // MARK: - User Actions

    private let onUpdate: () -> Void
    private let onDelete: () -> Void

    // MARK: - Dialog State

    @State
    private var isPresentingOptions: Bool = false

    // MARK: - Initializer

    init(
        user: UserDto,
        source: ImageSource,
        pipeline: ImagePipeline = .Swiftfin.posters,
        onUpdate: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.user = user
        self.source = source
        self.pipeline = pipeline
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }

    // MARK: - Body

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
