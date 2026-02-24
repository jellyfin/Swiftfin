//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension CustomDeviceProfilesView {

    struct EditDeviceProfileView: View {

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

        var body: some View {
            Form(systemImage: "doc") {
                contentView
            }
            .interactiveDismissDisabled(true)
            .navigationTitle(L10n.customProfile.localizedCapitalized)
            .alert(L10n.profileNotSaved, isPresented: $isPresentingNotSaved) {
                Button(L10n.close, role: .destructive) {
                    router.dismiss()
                }
            }
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
                .disabled(!isValid)
                #if os(iOS)
                    .buttonStyle(.toolbarPill)
                #endif
            }
            #if os(iOS)
            .navigationBarBackButtonHidden()
            .navigationBarCloseButton {
                isPresentingNotSaved = true
            }
            #else
            .onExitCommand {
                    isPresentingNotSaved = true
                }
            #endif
        }

        @ViewBuilder
        private var contentView: some View {

            Section(L10n.behavior) {
                Toggle(L10n.useAsTranscodingProfile, isOn: $profile.useAsTranscodingProfile)
            }

            Section {
                ChevronButton {
                    router.route(to: .editDeviceProfileAudio(selection: $profile.audio))
                } label: {
                    componentLabel(L10n.audio, value: profile.audio.map(\.displayTitle).joined(separator: ", "))
                }

                ChevronButton {
                    router.route(to: .editDeviceProfileVideo(selection: $profile.video))
                } label: {
                    componentLabel(L10n.video, value: profile.video.map(\.displayTitle).joined(separator: ", "))
                }

                ChevronButton {
                    router.route(to: .editDeviceProfileContainer(selection: $profile.container))
                } label: {
                    componentLabel(L10n.containers, value: profile.container.map(\.displayTitle).joined(separator: ", "))
                }
            } header: {
                Text("Components")
            } footer: {
                if !isValid {
                    Label(L10n.missingCodecValues, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }
        }

        private func componentLabel(_ title: String, value: String) -> LabeledContent<some View, EmptyView> {
            LabeledContent {
                EmptyView()
            } label: {
                LabeledContent {
                    if value.isEmpty {
                        Label(L10n.none, systemImage: "exclamationmark.circle.fill")
                            .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                    } else {
                        Text(value)
                    }
                } label: {
                    Text(title)
                }
                .labeledContentStyle(.deviceProfile)
                .if(UIDevice.isTV) { text in
                    text
                        .padding(.vertical)
                }
            }
        }
    }
}
