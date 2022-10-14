//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct VideoPlayerSettingsView: View {

    @Default(.VideoPlayer.autoPlay)
    private var autoPlay
    @Default(.VideoPlayer.jumpBackwardLength)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardLength)
    private var jumpForwardLength
    @Default(.VideoPlayer.playNextItem)
    private var playNextItem
    @Default(.VideoPlayer.playPreviousItem)
    private var playPreviousItem
    @Default(.VideoPlayer.resumeOffset)
    private var resumeOffset

    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize

    @Default(.VideoPlayer.Overlay.playbackButtonType)
    private var playbackButtonType
    @Default(.VideoPlayer.Overlay.sliderType)
    private var sliderType

    @Default(.VideoPlayer.Overlay.negativeTimestamp)
    private var negativeTimestamp
    @Default(.VideoPlayer.Overlay.showCurrentTimeWhileScrubbing)
    private var showCurrentTimeWhileScrubbing
    @Default(.VideoPlayer.Overlay.timestampType)
    private var timestampType

    @EnvironmentObject
    private var router: VideoPlayerSettingsCoordinator.Router

    var body: some View {
        Form {

            Toggle(L10n.autoPlay, isOn: $autoPlay)

            EnumPicker(title: L10n.jumpBackwardLength, selection: $jumpBackwardLength)

            EnumPicker(title: L10n.jumpForwardLength, selection: $jumpForwardLength)

            Toggle(L10n.playNextItem, isOn: $playNextItem)

            Toggle(L10n.playPreviousItem, isOn: $playPreviousItem)

            Section {
                Toggle("Resume offset", isOn: $resumeOffset)
            } footer: {
                Text("Resume content 5 seconds before the actual resume time")
            }

            Section("Subtitle") {

                ChevronButton(title: L10n.subtitleFont, subtitle: subtitleFontName)
                    .onSelect {
                        router.route(to: \.fontPicker)
                    }

                Stepper(value: $subtitleSize, in: 8 ... 24) {
                    HStack {
                        L10n.subtitleSize.text

                        Text("\(subtitleSize)")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Overlay") {

                EnumPicker(title: "Playback Buttons", selection: $playbackButtonType)

                EnumPicker(title: "Slider", selection: $sliderType)
            }

            Section("Timestamp") {

                Toggle("Negative Time", isOn: $negativeTimestamp)

                Toggle("Scrubbing Current Time", isOn: $showCurrentTimeWhileScrubbing)

                EnumPicker(title: "Timestamp Type", selection: $timestampType)
            }
        }
    }

//    @Default(.overlayType)
//    var overlayType
//    @Default(.shouldShowPlayPreviousItem)
//    var shouldShowPlayPreviousItem
//    @Default(.shouldShowPlayNextItem)
//    var shouldShowPlayNextItem
//    @Default(.shouldShowAutoPlay)
//    var shouldShowAutoPlay
//    @Default(.shouldShowJumpButtonsInOverlayMenu)
//    var shouldShowJumpButtonsInOverlayMenu
//    @Default(.shouldShowChaptersInfoInBottomOverlay)
//    var shouldShowChaptersInfoInBottomOverlay
//
//    var body: some View {
//        Form {
//            Section(header: L10n.overlay.text) {
//                Picker(L10n.overlayType, selection: $overlayType) {
//                    ForEach(OverlayType.allCases, id: \.self) { overlay in
//                        Text(overlay.label).tag(overlay)
//                    }
//                }
//
//                Toggle(isOn: $shouldShowPlayPreviousItem) {
//                    HStack {
//                        Image(systemName: "chevron.left.circle")
//                        L10n.playPreviousItem.text
//                    }
//                }
//
//                Toggle(isOn: $shouldShowPlayNextItem) {
//                    HStack {
//                        Image(systemName: "chevron.right.circle")
//                        L10n.playNextItem.text
//                    }
//                }
//
//                Toggle(isOn: $shouldShowAutoPlay) {
//                    HStack {
//                        Image(systemName: "play.circle.fill")
//                        L10n.autoPlay.text
//                    }
//                }
//
//                Toggle(isOn: $shouldShowChaptersInfoInBottomOverlay) {
//                    HStack {
//                        Image(systemName: "photo.on.rectangle")
//                        L10n.showChaptersInfoInBottomOverlay.text
//                    }
//                }
//
//                Toggle(L10n.editJumpLengths, isOn: $shouldShowJumpButtonsInOverlayMenu)
//            }
//        }
//    }
}
