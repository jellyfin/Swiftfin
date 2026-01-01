//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension CustomDeviceProfileSettingsView {

    struct EditCustomDeviceProfileView: View {

        @StoredValue(.User.customDeviceProfiles)
        private var customDeviceProfiles

        @Router
        private var router

        @State
        private var isPresentingNotSaved = false

        @StateObject
        private var profile: BindingBox<CustomDeviceProfile>

        private let createProfile: Bool

        private var isValid: Bool {
            profile.value.audio.isNotEmpty &&
                profile.value.video.isNotEmpty &&
                profile.value.container.isNotEmpty
        }

        init(profile: Binding<CustomDeviceProfile>?) {
            createProfile = profile == nil

            if let profile {
                self._profile = StateObject(wrappedValue: BindingBox(source: profile))
            } else {
                let empty = Binding<CustomDeviceProfile>(
                    get: { .init(type: .video) },
                    set: { _ in }
                )

                self._profile = StateObject(
                    wrappedValue: BindingBox(source: empty)
                )
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

                        if content.isEmpty {
                            Label(L10n.none, systemImage: "exclamationmark.circle.fill")
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
        }

        var body: some View {
            SplitFormWindowView()
                .descriptionView {
                    Image(systemName: "doc")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 400)
                }
                .contentView {
                    Section {
                        Toggle(L10n.useAsTranscodingProfile, isOn: $profile.value.useAsTranscodingProfile)
                            .padding(.vertical)
                    } header: {
                        HStack {
                            Text(L10n.customProfile)
                            Spacer()
                            Button(L10n.save) {
                                if createProfile {
                                    customDeviceProfiles.append(profile.value)
                                }
                                router.dismiss()
                            }
                            .disabled(!isValid)
                        }
                    }

                    codecSection(
                        title: L10n.audio,
                        content: profile.value.audio.map(\.displayTitle).joined(separator: ", ")
                    ) {
                        router.route(to: .editCustomDeviceProfileAudio(selection: $profile.value.audio))
                    }
                    .padding(.vertical)

                    codecSection(
                        title: L10n.video,
                        content: profile.value.video.map(\.displayTitle).joined(separator: ", ")
                    ) {
                        router.route(to: .editCustomDeviceProfileVideo(selection: $profile.value.video))
                    }
                    .padding(.vertical)

                    codecSection(
                        title: L10n.containers,
                        content: profile.value.container.map(\.displayTitle).joined(separator: ", ")
                    ) {
                        router.route(to: .editCustomDeviceProfileContainer(selection: $profile.value.container))
                    }
                    .padding(.vertical)

                    if !isValid {
                        Label(L10n.replaceDeviceProfileWarning, systemImage: "exclamationmark.circle.fill")
                    }
                }
                .navigationTitle(L10n.customProfile.localizedCapitalized)
                .alert(L10n.profileNotSaved, isPresented: $isPresentingNotSaved) {
                    Button(L10n.close, role: .destructive) {
                        router.dismiss()
                    }
                }
                .interactiveDismissDisabled(true)
        }
    }
}
