//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension CustomDeviceProfileSettingsView {

    struct EditCustomDeviceProfileView: View {

        @Default(.accentColor)
        private var accentColor

        @StoredValue(.User.customDeviceProfiles)
        private var customDeviceProfiles

        @Router
        private var router

        @State
        private var isPresentingNotSaved = false
        @State
        private var profile: CustomDeviceProfile

        private let createProfile: Bool
        private let source: Binding<CustomDeviceProfile>?

        private var isValid: Bool {
            profile.audio.isNotEmpty &&
                profile.video.isNotEmpty &&
                profile.container.isNotEmpty
        }

        init(profile: Binding<CustomDeviceProfile>?) {

            createProfile = profile == nil

            if let profile {
                self._profile = State(initialValue: profile.wrappedValue)
                self.source = profile
            } else {
                self._profile = State(initialValue: .init(type: .video))
                self.source = nil
            }
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
                        content: profile.audio.map(\.displayTitle).joined(separator: ", ")
                    ) {
                        router.route(to: .editCustomDeviceProfileAudio(selection: $profile.audio))
                    }

                    codecSection(
                        title: L10n.video,
                        content: profile.video.map(\.displayTitle).joined(separator: ", ")
                    ) {
                        router.route(to: .editCustomDeviceProfileVideo(selection: $profile.video))
                    }

                    codecSection(
                        title: L10n.containers,
                        content: profile.container.map(\.displayTitle).joined(separator: ", ")
                    ) {
                        router.route(to: .editCustomDeviceProfileContainer(selection: $profile.container))
                    }
                } footer: {
                    if !isValid {
                        Label(L10n.missingCodecValues, systemImage: "exclamationmark.circle.fill")
                            .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                    }
                }
            }
            .interactiveDismissDisabled(true)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .navigationBarCloseButton {
                isPresentingNotSaved = true
            }
            .navigationTitle(L10n.customProfile.localizedCapitalized)
            .topBarTrailing {
                Button(L10n.save) {
                    if createProfile {
                        customDeviceProfiles.append(profile)
                    } else {
                        source?.wrappedValue = profile
                    }

                    UIDevice.impact(.light)
                    router.dismiss()
                }
                .buttonStyle(.toolbarPill)
                .disabled(!isValid)
            }
            .alert(L10n.profileNotSaved, isPresented: $isPresentingNotSaved) {
                Button(L10n.close, role: .destructive) {
                    router.dismiss()
                }
            }
        }
    }
}
