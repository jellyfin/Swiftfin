//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

struct CustomDeviceProfilesView: View {

    @Default(.VideoPlayer.Playback.customDeviceProfileAction)
    private var customDeviceProfileAction

    @StoredValue(.User.customDeviceProfiles)
    private var customProfiles: [CustomDeviceProfile]

    @Router
    private var router

    private var isValid: Bool {
        customDeviceProfileAction == .add || customProfiles.isNotEmpty
    }

    private func deleteProfile(_ profile: CustomDeviceProfile) {
        if let index = customProfiles.firstIndex(of: profile) {
            customProfiles.remove(at: index)
        }
    }

    // MARK: - Body

    var body: some View {
        Form(systemImage: "doc.on.doc") {
            behaviorSection
            profilesSection
        }
        .navigationTitle(L10n.profiles)
        .topBarTrailing {
            if customProfiles.isNotEmpty {
                addButton
                #if os(iOS)
                .buttonStyle(.toolbarPill)
                #endif
            }
        }
    }

    @ViewBuilder
    private var behaviorSection: some View {
        Section(L10n.behavior) {
            #if os(iOS)
            Picker(L10n.behavior, selection: $customDeviceProfileAction)
            #else
            ListRowMenu(L10n.behavior, selection: $customDeviceProfileAction)
            #endif
        } footer: {
            if !isValid {
                Label(L10n.noDeviceProfileWarning, systemImage: "exclamationmark.circle.fill")
                    .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
            }
        } learnMore: {
            LabeledContent(
                L10n.add,
                value: L10n.customDeviceProfileAdd
            )
            LabeledContent(
                L10n.replace,
                value: L10n.customDeviceProfileReplace
            )
        }
    }

    @ViewBuilder
    private var profilesSection: some View {
        Section(L10n.profiles) {

            if customProfiles.isEmpty {
                addButton
            }

            ForEach($customProfiles, id: \.self) { $profile in
                ChevronButton {
                    router.route(to: .editDeviceProfile(profile: $profile))
                } label: {
                    LabeledContent {
                        EmptyView()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledContent(
                                L10n.audio,
                                value: profile.audio.map(\.displayTitle).joined(separator: ", ")
                            )
                            LabeledContent(
                                L10n.video,
                                value: profile.video.map(\.displayTitle).joined(separator: ", ")
                            )
                            LabeledContent(
                                L10n.containers,
                                value: profile.container.map(\.displayTitle).joined(separator: ", ")
                            )
                            LabeledContent(
                                L10n.useAsTranscodingProfile,
                                value: profile.useAsTranscodingProfile ? L10n.yes : L10n.no
                            )
                        }
                        .labeledContentStyle(.deviceProfile)
                        .if(UIDevice.isTV) { text in
                            text
                                .padding(.vertical)
                        }
                    }
                }
                #if os(iOS)
                .swipeActions {
                    Button(
                        L10n.delete,
                        systemImage: "trash",
                        action: {
                            deleteProfile(profile)
                        }
                    )
                    .tint(.red)
                }
                #else
                .contextMenu {
                        Button(role: .destructive) {
                            deleteProfile(profile)
                        } label: {
                            Label(L10n.delete, systemImage: "trash")
                        }
                    }
                #endif
            }
        }
    }

    private var addButton: some View {
        Button(L10n.add) {
            router.route(to: .createDeviceProfile)
        }
    }
}
