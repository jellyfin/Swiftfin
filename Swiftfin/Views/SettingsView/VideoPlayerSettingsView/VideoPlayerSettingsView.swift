//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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

    @Default(.VideoPlayer.Transition.pauseOnBackground)
    private var pauseOnBackground
    @Default(.VideoPlayer.Transition.playOnActive)
    private var playOnActive

    @EnvironmentObject
    private var router: VideoPlayerSettingsCoordinator.Router

    var body: some View {
        Form {

            ChevronButton(title: L10n.gestures)
                .onSelect {
                    router.route(to: \.gestureSettings)
                }

            CaseIterablePicker(title: L10n.jumpBackwardLength, selection: $jumpBackwardLength)
                .onListRowLongPress(reset: _jumpBackwardLength)

            CaseIterablePicker(title: L10n.jumpForwardLength, selection: $jumpForwardLength)
                .onListRowLongPress(reset: _jumpForwardLength)

            Section {

                BasicStepper(
                    title: L10n.resumeOffset,
                    value: $resumeOffset,
                    range: 0 ... 30,
                    step: 1
                )
                .valueFormatter {
                    $0.secondLabel
                }
                .onListRowLongPress(reset: _resumeOffset)
            } footer: {
                Text(L10n.resumeOffsetDescription)
            }

            Section(L10n.buttons) {

                CaseIterablePicker(title: L10n.playbackButtons, selection: $playbackButtonType)
                    .onListRowLongPress(reset: _playbackButtonType)

                Toggle(isOn: $showJumpButtons) {
                    HStack {
                        Image(systemName: "goforward")
                        Text(L10n.jump)
                    }
                }
                .onListRowLongPress(reset: _showJumpButtons)

                ChevronButton(title: L10n.barButtons)
                    .onSelect {
                        router.route(to: \.actionButtonSelector, $barActionButtons)
                    }

                ChevronButton(title: L10n.menuButtons)
                    .onSelect {
                        router.route(to: \.actionButtonSelector, $menuActionButtons)
                    }
            }

            Section(L10n.slider) {

                Toggle(L10n.chapterSlider, isOn: $chapterSlider)
                    .onListRowLongPress(reset: _chapterSlider)

                ColorPicker(selection: $sliderColor, supportsOpacity: false) {
                    Text(L10n.sliderColor)
                }
                .onListRowLongPress(reset: _sliderColor)

                CaseIterablePicker(title: L10n.sliderType, selection: $sliderType)
                    .onListRowLongPress(reset: _sliderType)
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
                .onListRowLongPress(reset: _subtitleSize)

                ColorPicker(selection: $subtitleColor, supportsOpacity: false) {
                    Text(L10n.subtitleColor)
                }
                .onListRowLongPress(reset: _subtitleColor)
            } header: {
                Text(L10n.subtitle)
            } footer: {
                // TODO: better wording
                Text("Settings only affect some subtitle types")
            }

            Section(L10n.timestamp) {

                Toggle(L10n.scrubCurrentTime, isOn: $showCurrentTimeWhileScrubbing)
                    .onListRowLongPress(reset: _showCurrentTimeWhileScrubbing)

                CaseIterablePicker(title: L10n.timestampType, selection: $timestampType)
                    .onListRowLongPress(reset: _timestampType)

                CaseIterablePicker(title: L10n.trailingValue, selection: $trailingTimestampType)
                    .onListRowLongPress(reset: _trailingTimestampType)
            }

            Section(L10n.transition) {

                Toggle(L10n.pauseOnBackground, isOn: $pauseOnBackground)
                    .onListRowLongPress(reset: _pauseOnBackground)

                Toggle(L10n.playOnActive, isOn: $playOnActive)
                    .onListRowLongPress(reset: _playOnActive)
            }
        }
        .navigationTitle(L10n.videoPlayer)
        .onChange(of: barActionButtons) { newValue in
            autoPlayEnabled = newValue.contains(.autoPlay) || menuActionButtons.contains(.autoPlay)
        }
        .onChange(of: menuActionButtons) { newValue in
            autoPlayEnabled = newValue.contains(.autoPlay) || barActionButtons.contains(.autoPlay)
        }
    }
}
