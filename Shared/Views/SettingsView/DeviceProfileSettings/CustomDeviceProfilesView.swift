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

    private var addButton: some View {
        Button(L10n.add) {
            router.route(to: .createDeviceProfile)
        }
    }

    private func deleteButton(profile: CustomDeviceProfile) -> some View {
        Button(L10n.delete, systemImage: "trash", role: .destructive) {
            customProfiles.removeFirst(equalTo: profile)
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

    private var customProfileView: some View {
        Section(customDeviceProfileAction == .add ? L10n.custom : L10n.profiles) {

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
                        profileView(
                            useAsTranscodingProfile: profile.useAsTranscodingProfile,
                            audio: profile.audio,
                            video: profile.video,
                            containers: profile.container
                        )
                    }
                }
                #if os(iOS)
                .swipeActions {
                    deleteButton(profile: profile)
                }
                #else
                .contextMenu {
                        deleteButton(profile: profile)
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
                    Button {} label: {
                        profileView(
                            useAsTranscodingProfile: false,
                            audio: profile.audioCodec.components(of: AudioCodec.self),
                            video: profile.videoCodec.components(of: VideoCodec.self),
                            containers: profile.container.components(of: MediaContainer.self)
                        )
                    }
                    .foregroundStyle(.primary, .secondary)
                }

                ForEach(Array(videoPlayerType.transcodingProfiles.enumerated()), id: \.offset) { _, profile in
                    Button {} label: {
                        profileView(
                            useAsTranscodingProfile: true,
                            audio: profile.audioCodec.components(of: AudioCodec.self),
                            video: profile.videoCodec.components(of: VideoCodec.self),
                            containers: profile.container.components(of: MediaContainer.self)
                        )
                    }
                    .foregroundStyle(.primary, .secondary)
                }
            }
        }
    }

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
}
