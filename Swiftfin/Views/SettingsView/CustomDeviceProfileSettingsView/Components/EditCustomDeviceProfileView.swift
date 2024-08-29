//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension CustomDeviceProfileSettingsView {

    struct EditCustomDeviceProfileView: View {

        @Binding
        private var profile: CustomDeviceProfile
        @State
        private var updateProfile: CustomDeviceProfile

        @EnvironmentObject
        private var router: SettingsCoordinator.Router

        private var isValid: Bool {
            updateProfile.audio.isNotEmpty &&
                updateProfile.video.isNotEmpty &&
                updateProfile.container.isNotEmpty
        }

        init(profile: Binding<CustomDeviceProfile>) {
            self._profile = profile
            self.updateProfile = profile.wrappedValue
        }

        @ViewBuilder
        private func codecSection(
            title: String,
            content: String,
            onSelect: @escaping () -> Void
        ) -> some View {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        if content.isEmpty {
                            Label(L10n.none, systemImage: "exclamationmark.circle.fill")
                                .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                                .foregroundColor(.secondary)
                        } else {
                            Text(content)
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.subheadline)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.body.weight(.regular))
                        .foregroundColor(.secondary)
                }
            }
            .foregroundStyle(.primary)
        }

        var body: some View {
            Form {
                Toggle(L10n.useAsTranscodingProfile, isOn: $profile.useAsTranscodingProfile)

                Section {
                    codecSection(
                        title: L10n.audio,
                        content: updateProfile.audio.map(\.displayTitle).joined(separator: ", ")
                    ) {
                        router.route(to: \.customDeviceAudioEditor, $updateProfile.audio)
                    }

                    codecSection(
                        title: L10n.video,
                        content: updateProfile.video.map(\.displayTitle).joined(separator: ", ")
                    ) {
                        router.route(to: \.customDeviceVideoEditor, $updateProfile.video)
                    }

                    codecSection(
                        title: L10n.containers,
                        content: updateProfile.container.map(\.displayTitle).joined(separator: ", ")
                    ) {
                        router.route(to: \.customDeviceContainerEditor, $updateProfile.container)
                    }
                } footer: {
                    if !isValid {
                        Label("Current profile values may cause playback issues", systemImage: "exclamationmark.circle.fill")
                            .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                    }
                }
            }
            .navigationTitle(L10n.customProfile)
            .onChange(of: updateProfile) { newValue in
                profile = newValue
            }
        }
    }
}
