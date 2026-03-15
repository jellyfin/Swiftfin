//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

struct VideoPlayerSettingsView: View {

    #if os(tvOS)
    typealias PlatformPicker = ListRowMenu
    #else
    typealias PlatformPicker = Picker
    #endif

    // MARK: - Button Defaults

    @Default(.VideoPlayer.jumpBackwardInterval)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardInterval)
    private var jumpForwardLength
    @Default(.VideoPlayer.barActionButtons)
    private var barActionButtons
    @Default(.VideoPlayer.menuActionButtons)
    private var menuActionButtons

    // MARK: - Resume Defaults

    @Default(.VideoPlayer.resumeOffset)
    private var resumeOffset

    // MARK: - Slider Defaults

    @Default(.VideoPlayer.Overlay.chapterSlider)
    private var chapterSlider
    @StoredValue(.User.previewImageScrubbing)
    private var previewImageScrubbing: PreviewImageScrubbingOption

    // MARK: - Subtitle Defaults

    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize
    @Default(.VideoPlayer.Subtitle.subtitleColor)
    private var subtitleColor

    // MARK: - Timestamp Defaults

    @Default(.VideoPlayer.Overlay.trailingTimestampType)
    private var trailingTimestampType

    @Router
    private var router

    @StateObject
    private var viewModel: ServerUserAdminViewModel

    @State
    private var userConfiguration: UserConfiguration

    init() {
        /// If there is no User or UserSession, updating the user on the server has the potential of nuking all settings.
        /// - Force Unwrap might crash but this is to prevent malformed UserDTO updating over real UserDTOs
        let user = Container.shared.currentUserSession()!.user.data

        self.userConfiguration = user.configuration!
        self._viewModel = StateObject(wrappedValue: ServerUserAdminViewModel(user: user))
    }

    // MARK: - Body

    var body: some View {
        Form(systemImage: "tv") {
            #if os(iOS)
            gestureSettings
            #endif
            buttonSettings
            resumeSettings
            sliderSettings
            timestampSettings
            audioSettings
            subtitleSettings
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .navigationTitle(L10n.videoPlayer.localizedCapitalized)
    }

    // MARK: - Gesture Settings

    #if os(iOS)
    @ViewBuilder
    private var gestureSettings: some View {
        Section(L10n.gestures) {
            ChevronButton(L10n.gestures) {
                router.route(to: .gestureSettings)
            }
        }
    }
    #endif

    // MARK: - Button Settings

    @ViewBuilder
    private var buttonSettings: some View {
        Section(L10n.buttons) {
            JumpIntervalPicker(L10n.jumpBackwardLength, selection: $jumpBackwardLength)
            JumpIntervalPicker(L10n.jumpForwardLength, selection: $jumpForwardLength)

            ChevronButton(L10n.barButtons) {
                router.route(to: .actionBarButtonSelector(
                    selectedButtonsBinding: $barActionButtons
                ))
            }

            ChevronButton(L10n.menuButtons) {
                router.route(to: .actionMenuButtonSelector(
                    selectedButtonsBinding: $menuActionButtons
                ))
            }
        }
        .onChange(of: barActionButtons) { newValue in
            let enabled = newValue.contains(.autoPlay) || menuActionButtons.contains(.autoPlay)

            userConfiguration.enableNextEpisodeAutoPlay = enabled
            viewModel.updateConfiguration(userConfiguration)
        }
        .onChange(of: menuActionButtons) { newValue in
            let enabled = newValue.contains(.autoPlay) || barActionButtons.contains(.autoPlay)

            userConfiguration.enableNextEpisodeAutoPlay = enabled
            viewModel.updateConfiguration(userConfiguration)
        }
    }

    // MARK: - Resume Settings

    @ViewBuilder
    private var resumeSettings: some View {
        Section {
            Stepper(L10n.resumeOffset, value: $resumeOffset, in: 0 ... 30, step: 1) {
                LabeledContent(L10n.resumeOffset) {
                    Text(resumeOffset, format: SecondFormatter())
                }
            }

            Toggle(L10n.autoPlay, isOn: Binding(
                get: { viewModel.user.configuration?.enableNextEpisodeAutoPlay ?? true },
                set: { newValue in
                    userConfiguration.enableNextEpisodeAutoPlay = newValue
                    viewModel.updateConfiguration(userConfiguration)
                }
            ))
        } header: {
            Text(L10n.resume)
        } footer: {
            Text(L10n.resumeOffsetDescription)
        }
    }

    // MARK: - Slider Settings

    @ViewBuilder
    private var sliderSettings: some View {
        Section(L10n.slider) {
            Toggle(L10n.chapterSlider, isOn: $chapterSlider)
            PlatformPicker(L10n.previewImage, selection: $previewImageScrubbing)
        }
    }

    // MARK: - Timestamp Settings

    @ViewBuilder
    private var timestampSettings: some View {
        Section(L10n.timestamp) {
            PlatformPicker(L10n.trailingValue, selection: $trailingTimestampType)
        }
    }

    // MARK: - Audio Settings

    @ViewBuilder
    private var audioSettings: some View {
        Section(L10n.audio) {
            CulturePicker("Preferred language", threeLetterISOLanguageName: Binding(
                get: { viewModel.user.configuration?.audioLanguagePreference },
                set: { newValue in
                    userConfiguration.audioLanguagePreference = newValue
                    viewModel.updateConfiguration(userConfiguration)
                }
            ))
            Toggle("Play default track", isOn: Binding(
                get: { viewModel.user.configuration?.isPlayDefaultAudioTrack ?? true },
                set: { newValue in
                    userConfiguration.isPlayDefaultAudioTrack = newValue
                    viewModel.updateConfiguration(userConfiguration)
                }
            ))
            Toggle("Remember track selection", isOn: Binding(
                get: { viewModel.user.configuration?.isRememberAudioSelections ?? true },
                set: { newValue in
                    userConfiguration.isRememberAudioSelections = newValue
                    viewModel.updateConfiguration(userConfiguration)
                }
            ))
        } learnMore: {
            LabeledContent(
                "Play default",
                value: "Always played the first track marks as Default, even if not in your language."
            )
            LabeledContent(
                "Remember track selection",
                value: "Remembers your selected track the next time you play this item."
            )
        }
    }

    // MARK: - Subtitle Settings

    @ViewBuilder
    private var subtitleSettings: some View {
        Section(L10n.subtitles) {
            CulturePicker("Preferred language", threeLetterISOLanguageName: Binding(
                get: { viewModel.user.configuration?.subtitleLanguagePreference },
                set: { newValue in
                    userConfiguration.subtitleLanguagePreference = newValue
                    viewModel.updateConfiguration(userConfiguration)
                }
            ))

            PlatformPicker("Subtitle mode", selection: Binding(
                get: { viewModel.user.configuration?.subtitleMode ?? .default },
                set: { newValue in
                    userConfiguration.subtitleMode = newValue
                    viewModel.updateConfiguration(userConfiguration)
                }
            ))

            Toggle("Remember track selection", isOn: Binding(
                get: { viewModel.user.configuration?.isRememberSubtitleSelections ?? true },
                set: { newValue in
                    userConfiguration.isRememberSubtitleSelections = newValue
                    viewModel.updateConfiguration(userConfiguration)
                }
            ))
        } learnMore: {
            LabeledContent(
                L10n.default,
                value: "Play the subtitle track marked as Default, even if it doesn't match your preferred language."
            )
            LabeledContent(
                "Always",
                value: "Always show subtitles, preferring your preferred language when available."
            )
            LabeledContent(
                "Only forced",
                value: "Only show subtitles marked as Forced, typically for foreign language sections."
            )
            LabeledContent(
                L10n.none,
                value: "Never automatically display subtitles."
            )
            LabeledContent(
                "Smart",
                value: "Show subtitles when the audio language differs from your preferred language."
            )
        }

        Section {
            ChevronButton(L10n.subtitleFont, subtitle: subtitleFontName) {
                router.route(to: .fontPicker(selection: $subtitleFontName))
            }

            Stepper(L10n.subtitleSize, value: $subtitleSize, in: 1 ... 20, step: 1) {
                LabeledContent(L10n.subtitleSize) {
                    Text(subtitleSize.description)
                }
            }

            ColorPicker(L10n.subtitleColor, selection: $subtitleColor, supportsOpacity: false)
        } footer: {
            // TODO: better wording
            Text(L10n.subtitlesDisclaimer)
        }
    }
}
