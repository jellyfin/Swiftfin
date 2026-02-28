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

    // MARK: - Button Defaults

    @Default(.VideoPlayer.jumpBackwardInterval)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardInterval)
    private var jumpForwardLength

    @Default(.VideoPlayer.barActionButtons)
    private var barActionButtons
    @Default(.VideoPlayer.menuActionButtons)
    private var menuActionButtons
    @Default(.VideoPlayer.autoPlayEnabled)
    private var autoPlayEnabled

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

    @StateObject
    private var viewModel: ServerUserAdminViewModel

    @Router
    private var router

    init() {
        /// If there is no User or UserSession, updating the user on the server has the potential of nuking all settings.
        /// - Force Unwrap might crash but this is to prevent malformed UserDTO updating over real UserDTOs
        _viewModel = StateObject(wrappedValue: ServerUserAdminViewModel(user: Container.shared.currentUserSession()!.user.data))
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

            // TODO: Migrate these routes to tvOS with Player UI
            #if iOS
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
            #endif
        }
        #if iOS
        .onChange(of: barActionButtons) { newValue in
                autoPlayEnabled = newValue.contains(.autoPlay) || menuActionButtons.contains(.autoPlay)
            }
            .onChange(of: menuActionButtons) { newValue in
                autoPlayEnabled = newValue.contains(.autoPlay) || barActionButtons.contains(.autoPlay)
            }
        #endif
    }

    // MARK: - Resume Settings

    @ViewBuilder
    private var resumeSettings: some View {
        Section {
            #if os(iOS)
            Stepper(value: $resumeOffset, in: 0 ... 30, step: 1) {
                LabeledContent(L10n.resumeOffset) {
                    Text(resumeOffset, format: SecondFormatter())
                }
            }
            #else
            Stepper(L10n.resumeOffset, value: $resumeOffset, in: 0 ... 30, step: 1, format: SecondFormatter()) {
                LabeledContent {
                    Text(resumeOffset, format: SecondFormatter())
                } label: {
                    Text(L10n.resumeOffset)
                }
            }
            #endif
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

            #if os(iOS)
            Picker(L10n.previewImage, selection: $previewImageScrubbing)
            #else
            ListRowMenu(L10n.previewImage, selection: $previewImageScrubbing)
            #endif
        }
    }

    // MARK: - Timestamp Settings

    @ViewBuilder
    private var timestampSettings: some View {
        Section(L10n.timestamp) {
            #if os(iOS)
            Picker(L10n.trailingValue, selection: $trailingTimestampType)
            #else
            ListRowMenu(L10n.trailingValue, selection: $trailingTimestampType)
            #endif
        }
    }

    // MARK: - Audio Settings

    @ViewBuilder
    private var audioSettings: some View {
        Section(L10n.audio) {
            CulturePicker("Default language", threeLetterISOLanguageName: Binding(
                get: { viewModel.user.configuration?.audioLanguagePreference },
                set: { newValue in
                    var configuration = viewModel.user.configuration ?? UserConfiguration()
                    configuration.audioLanguagePreference = newValue
                    viewModel.updateConfiguration(configuration)
                }
            ))
            Toggle("Play default track", isOn: Binding(
                get: { viewModel.user.configuration?.isPlayDefaultAudioTrack ?? true },
                set: { newValue in
                    var configuration = viewModel.user.configuration ?? UserConfiguration()
                    configuration.isPlayDefaultAudioTrack = newValue
                    viewModel.updateConfiguration(configuration)
                }
            ))
            Toggle("Remember track selection", isOn: Binding(
                get: { viewModel.user.configuration?.isRememberAudioSelections ?? true },
                set: { newValue in
                    var configuration = viewModel.user.configuration ?? UserConfiguration()
                    configuration.isRememberAudioSelections = newValue
                    viewModel.updateConfiguration(configuration)
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
            CulturePicker("Default language", threeLetterISOLanguageName: Binding(
                get: { viewModel.user.configuration?.subtitleLanguagePreference },
                set: { newValue in
                    var configuration = viewModel.user.configuration ?? UserConfiguration()
                    configuration.subtitleLanguagePreference = newValue
                    viewModel.updateConfiguration(configuration)
                }
            ))

            #if os(iOS)
            Picker("Subtitle mode", selection: Binding(
                get: { viewModel.user.configuration?.subtitleMode ?? .default },
                set: { newValue in
                    var configuration = viewModel.user.configuration ?? UserConfiguration()
                    configuration.subtitleMode = newValue
                    viewModel.updateConfiguration(configuration)
                }
            ))
            #else
            ListRowMenu("Subtitle mode", selection: Binding(
                get: { viewModel.user.configuration?.subtitleMode ?? .default },
                set: { newValue in
                    var configuration = viewModel.user.configuration ?? UserConfiguration()
                    configuration.subtitleMode = newValue
                    viewModel.updateConfiguration(configuration)
                }
            ))
            #endif

            Toggle("Remember track selection", isOn: Binding(
                get: { viewModel.user.configuration?.isRememberSubtitleSelections ?? true },
                set: { newValue in
                    var configuration = viewModel.user.configuration ?? UserConfiguration()
                    configuration.isRememberSubtitleSelections = newValue
                    viewModel.updateConfiguration(configuration)
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

            #if os(iOS)
            Stepper(value: $subtitleSize, in: 1 ... 20, step: 1) {
                LabeledContent(L10n.subtitleSize) {
                    Text(subtitleSize.description)
                }
            }
            #else
            Stepper(L10n.subtitleSize, value: $subtitleSize, in: 1 ... 20, step: 1) {
                LabeledContent(L10n.subtitleSize) {
                    Text(subtitleSize.description)
                }
            }
            #endif

            ColorPicker(L10n.subtitleColor, selection: $subtitleColor, supportsOpacity: false)
        } footer: {
            // TODO: better wording
            Text(L10n.subtitlesDisclaimer)
        }
    }
}
