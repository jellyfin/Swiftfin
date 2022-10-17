//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import Stinsen
import SwiftUI
import VLCUI

final class VideoPlayerSettingsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \VideoPlayerSettingsCoordinator.start)

    @Root
    var start = makeStart
    @Route(.push)
    var fontPicker = makeFontPicker

    @ViewBuilder
    func makeFontPicker() -> some View {
        FontPickerView()
            .navigationTitle(L10n.subtitleFont)
    }

    @ViewBuilder
    func makeStart() -> some View {
        VideoPlayerSettingsView()
    }
}

final class PlaybackSettingsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \PlaybackSettingsCoordinator.start)

    @Root
    var start = makeStart
    @Route(.push)
    var overlaySettings = makeVideoPlayerSettings
    @Route(.push)
    var mediaStreamInfo = makeMediaStreamInfo
    @Route(.push)
    var playbackInformation = makePlaybackInformation

    func makeVideoPlayerSettings() -> VideoPlayerSettingsCoordinator {
        VideoPlayerSettingsCoordinator()
    }

    @ViewBuilder
    func makeMediaStreamInfo(mediaStream: MediaStream) -> some View {
        MediaStreamInfoView(mediaStream: mediaStream)
    }

    @ViewBuilder
    func makePlaybackInformation() -> some View {
        PlaybackInformationView()
    }

    @ViewBuilder
    func makeStart() -> some View {
        PlaybackSettingsView()
    }
}

struct SplitText: View {

    let leading: String
    let trailing: String

    var body: some View {
        HStack {
            Text(leading)

            Spacer()

            Text(trailing)
                .foregroundColor(.secondary)
        }
    }
}

struct ChevronButton: View {

    let title: String
    let subtitle: String?
    private var onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                if let subtitle {
                    Text(subtitle)
                        .foregroundColor(.gray)
                }

                Image(systemName: "chevron.right")
            }
        }
    }
}

extension ChevronButton {
    init(title: String, subtitle: String? = nil) {
        self.init(
            title: title,
            subtitle: subtitle,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}

struct PlaybackSettingsView: View {

    @EnvironmentObject
    private var currentSecondsHandler: CurrentSecondsHandler
    @EnvironmentObject
    private var viewModel: VideoPlayerViewModel
    @EnvironmentObject
    private var router: PlaybackSettingsCoordinator.Router

    @Environment(\.presentingPlaybackSettings)
    @Binding
    private var presentingPlaybackSettings

    var body: some View {
        Form {
            Section {
                Button {
                    router.route(to: \.overlaySettings)
                } label: {
                    Text("Overlay Settings")
                }

                Button {
                    router.route(to: \.playbackInformation)
                } label: {
                    Text("Playback Information")
                }

            } header: {
                EmptyView()
            }

            Section("Audio") {
                ForEach(viewModel.audioStreams, id: \.displayTitle) { mediaStream in
                    ChevronButton(title: mediaStream.displayTitle ?? .emptyDash)
                        .onSelect {
                            router.route(to: \.mediaStreamInfo, mediaStream)
                        }
                }
            }

            Section("Subtitle") {
                ForEach(viewModel.subtitleStreams, id: \.displayTitle) { mediaStream in
                    ChevronButton(title: mediaStream.displayTitle ?? .emptyDash)
                        .onSelect {
                            router.route(to: \.mediaStreamInfo, mediaStream)
                        }
                }
            }
        }
        .navigationTitle("Playback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
//                    withAnimation {
                    presentingPlaybackSettings = false
//                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
//                        .frame(width: 44, height: 50)
                }
            }
        }
    }
}
