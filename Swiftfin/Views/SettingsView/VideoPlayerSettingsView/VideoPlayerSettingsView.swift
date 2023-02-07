//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct VideoPlayerSettingsView: View {

    // TODO: Organize

    @Default(.VideoPlayer.autoPlayEnabled)
    private var autoPlayEnabled

    @Default(.VideoPlayer.jumpBackwardLength)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardLength)
    private var jumpForwardLength
    @Default(.VideoPlayer.resumeOffset)
    private var resumeOffset

    @Default(.VideoPlayer.showJumpButtons)
    private var showJumpButtons

    @Default(.VideoPlayer.barActionButtons)
    private var barActionButtons
    @Default(.VideoPlayer.menuActionButtons)
    private var menuActionButtons

    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize
    @Default(.VideoPlayer.Subtitle.subtitleColor)
    private var subtitleColor

    @Default(.VideoPlayer.Overlay.chapterSlider)
    private var chapterSlider
    @Default(.VideoPlayer.Overlay.playbackButtonType)
    private var playbackButtonType
    @Default(.VideoPlayer.Overlay.sliderColor)
    private var sliderColor
    @Default(.VideoPlayer.Overlay.sliderType)
    private var sliderType

    @Default(.VideoPlayer.Overlay.trailingTimestampType)
    private var trailingTimestampType
    @Default(.VideoPlayer.Overlay.showCurrentTimeWhileScrubbing)
    private var showCurrentTimeWhileScrubbing
    @Default(.VideoPlayer.Overlay.timestampType)
    private var timestampType

    @EnvironmentObject
    private var router: VideoPlayerSettingsCoordinator.Router

    var body: some View {
        Form {

            ChevronButton(title: "Gestures")
                .onSelect {
                    router.route(to: \.gestureSettings)
                }

            EnumPicker(title: L10n.jumpBackwardLength, selection: $jumpBackwardLength)

            EnumPicker(title: L10n.jumpForwardLength, selection: $jumpForwardLength)

            Section {

                BasicStepper(
                    title: "Resume Offset",
                    value: $resumeOffset,
                    range: 0 ... 30,
                    step: 1
                )
                .valueFormatter {
                    $0.secondFormat
                }
            } footer: {
                Text("Resume content seconds before the recorded resume time")
            }

            Section("Buttons") {

                EnumPicker(title: "Playback Buttons", selection: $playbackButtonType)

                Toggle(isOn: $showJumpButtons) {
                    HStack {
                        Image(systemName: "goforward")
                        Text("Jump")
                    }
                }

                ChevronButton(title: "Bar Buttons")
                    .onSelect {
                        router.route(to: \.actionButtonSelector, $barActionButtons)
                    }

                ChevronButton(title: "Menu Buttons")
                    .onSelect {
                        router.route(to: \.actionButtonSelector, $menuActionButtons)
                    }
            }

            Section("Slider") {

                Toggle("Chapter Slider", isOn: $chapterSlider)

                ColorPicker(selection: $sliderColor, supportsOpacity: false) {
                    Text("Slider Color")
                }

                EnumPicker(title: "Slider Type", selection: $sliderType)
            }

            Section {

                ChevronButton(title: L10n.subtitleFont, subtitle: subtitleFontName)
                    .onSelect {
                        router.route(to: \.fontPicker, $subtitleFontName)
                    }

                BasicStepper(
                    title: L10n.subtitleSize,
                    value: $subtitleSize,
                    range: 8 ... 24,
                    step: 1
                )

                ColorPicker(selection: $subtitleColor, supportsOpacity: false) {
                    Text("Subtitle Color")
                }
            } header: {
                Text("Subtitle")
            } footer: {
                // TODO: better wording
                Text("Settings only affect some subtitle types")
            }

            Section("Timestamp") {

                Toggle("Scrub Current Time", isOn: $showCurrentTimeWhileScrubbing)

                EnumPicker(title: "Timestamp Type", selection: $timestampType)

                EnumPicker(title: "Trailing Value", selection: $trailingTimestampType)
            }
        }
        .navigationTitle("Video Player")
        .onChange(of: barActionButtons) { newValue in
            autoPlayEnabled = newValue.contains(.autoPlay) || menuActionButtons.contains(.autoPlay)
        }
        .onChange(of: menuActionButtons) { newValue in
            autoPlayEnabled = newValue.contains(.autoPlay) || barActionButtons.contains(.autoPlay)
        }
    }
}
