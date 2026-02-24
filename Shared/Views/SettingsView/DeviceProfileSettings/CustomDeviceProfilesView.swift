//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct CustomDeviceProfilesView: View {

    @Default(.VideoPlayer.Playback.customDeviceProfileAction)
    private var customDeviceProfileAction
    @Default(.VideoPlayer.videoPlayerType)
    private var videoPlayerType

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

    private var addButton: some View {
        Button(L10n.add) {
            router.route(to: .createDeviceProfile)
        }
    }

    var body: some View {
        Form(systemImage: "doc.on.doc") {
            behaviorView
            customProfileView
            defaultProfileView
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
    private var behaviorView: some View {
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
    private var customProfileView: some View {
        Section(customDeviceProfileAction == .add ? L10n.custom : L10n.profiles) {

            if customProfiles.isEmpty {
                addButton
            }

            ForEach($customProfiles, id: \.self) { $profile in
                profileButton(
                    useAsTranscodingProfile: profile.useAsTranscodingProfile,
                    audio: profile.audio,
                    video: profile.video,
                    containers: profile.container
                ) {
                    router.route(to: .editDeviceProfile(profile: $profile))
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

    @ViewBuilder
    private var defaultProfileView: some View {
        if customDeviceProfileAction == .add {
            Section(L10n.default) {
                ForEach(Array(videoPlayerType.directPlayProfiles.enumerated()), id: \.offset) { _, profile in
                    ListRow {} content: {
                        profileView(
                            useAsTranscodingProfile: false,
                            audio: profile.audioCodec.components(of: AudioCodec.self),
                            video: profile.videoCodec.components(of: VideoCodec.self),
                            containers: profile.container.components(of: MediaContainer.self)
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .isSeparatorVisible(false)
                }

                ForEach(Array(videoPlayerType.transcodingProfiles.enumerated()), id: \.offset) { _, profile in
                    ListRow {} content: {
                        profileView(
                            useAsTranscodingProfile: true,
                            audio: profile.audioCodec.components(of: AudioCodec.self),
                            video: profile.videoCodec.components(of: VideoCodec.self),
                            containers: profile.container.components(of: MediaContainer.self)
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .isSeparatorVisible(false)
                }
            }
        }
    }

    @ViewBuilder
    private func profileView(
        useAsTranscodingProfile: Bool,
        audio: [AudioCodec],
        video: [VideoCodec],
        containers: [MediaContainer]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent(
                L10n.useAsTranscodingProfile,
                value: useAsTranscodingProfile ? L10n.yes : L10n.no
            )
            LabeledContent(
                L10n.audio,
                value: audio.map(\.displayTitle).joined(separator: ", ")
            )
            LabeledContent(
                L10n.video,
                value: video.map(\.displayTitle).joined(separator: ", ")
            )
            LabeledContent(
                L10n.containers,
                value: containers.isEmpty
                    ? L10n.all
                    : containers.map(\.displayTitle).joined(separator: ", ")
            )
        }
        .labeledContentStyle(.deviceProfile)
        .if(UIDevice.isTV) { view in
            view
                .padding(.vertical)
        }
    }

    @ViewBuilder
    private func profileButton(
        useAsTranscodingProfile: Bool,
        audio: [AudioCodec],
        video: [VideoCodec],
        containers: [MediaContainer],
        action: @escaping () -> Void
    ) -> some View {
        ChevronButton(action: action) {
            LabeledContent {
                EmptyView()
            } label: {
                profileView(
                    useAsTranscodingProfile: useAsTranscodingProfile,
                    audio: audio,
                    video: video,
                    containers: containers
                )
            }
        }
    }
}
