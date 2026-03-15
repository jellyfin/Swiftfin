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

    init() {
        /// If there is no User or UserSession, updating the user on the server has the potential of nuking all settings.
        /// - Force Unwrap might crash but this is to prevent malformed UserDTO updating over real UserDTOs
        _viewModel = StateObject(wrappedValue: ServerUserAdminViewModel(user: Container.shared.currentUserSession()!.user.data))
    }

    private func updateConfiguration(_ modify: (inout UserConfiguration) -> Void) {
        guard var configuration = viewModel.user.configuration else { return }
        modify(&configuration)
        viewModel.updateConfiguration(configuration)
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
            updateConfiguration { $0.enableNextEpisodeAutoPlay = enabled }
        }
        .onChange(of: menuActionButtons) { newValue in
            let enabled = newValue.contains(.autoPlay) || barActionButtons.contains(.autoPlay)
            updateConfiguration { $0.enableNextEpisodeAutoPlay = enabled }
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
                get: { viewModel.user.configuration?.enableNextEpisodeAutoPlay == true },
                set: { newValue in
                    updateConfiguration { $0.enableNextEpisodeAutoPlay = newValue }
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
            CulturePicker(L10n.preferredLanguage, threeLetterISOLanguageName: Binding(
                get: { viewModel.user.configuration?.audioLanguagePreference },
                set: { newValue in
                    updateConfiguration { $0.audioLanguagePreference = newValue }
                }
            ))
            Toggle(L10n.playDefaultTrack, isOn: Binding(
                get: { viewModel.user.configuration?.isPlayDefaultAudioTrack == true },
                set: { newValue in
                    updateConfiguration { $0.isPlayDefaultAudioTrack = newValue }
                }
            ))
            Toggle(L10n.rememberTrackSelection, isOn: Binding(
                get: { viewModel.user.configuration?.isRememberAudioSelections == true },
                set: { newValue in
                    updateConfiguration { $0.isRememberAudioSelections = newValue }
                }
            ))
        } learnMore: {
            LabeledContent(
                L10n.playDefault,
                value: L10n.playDefaultTrackDescription
            )
            LabeledContent(
                L10n.rememberTrackSelection,
                value: L10n.rememberTrackSelectionDescription
            )
        }
    }

    // MARK: - Subtitle Settings

    @ViewBuilder
    private var subtitleSettings: some View {
        Section(L10n.subtitles) {
            CulturePicker(L10n.preferredLanguage, threeLetterISOLanguageName: Binding(
                get: { viewModel.user.configuration?.subtitleLanguagePreference },
                set: { newValue in
                    updateConfiguration { $0.subtitleLanguagePreference = newValue }
                }
            ))

            PlatformPicker(L10n.subtitleMode, selection: Binding(
                get: { viewModel.user.configuration?.subtitleMode ?? .default },
                set: { newValue in
                    updateConfiguration { $0.subtitleMode = newValue }
                }
            ))

            Toggle(L10n.rememberTrackSelection, isOn: Binding(
                get: { viewModel.user.configuration?.isRememberSubtitleSelections == true },
                set: { newValue in
                    updateConfiguration { $0.isRememberSubtitleSelections = newValue }
                }
            ))
        } learnMore: {
            LabeledContent(
                L10n.default,
                value: L10n.subtitleModeDefaultDescription
            )
            LabeledContent(
                L10n.always,
                value: L10n.subtitleModeAlwaysDescription
            )
            LabeledContent(
                L10n.onlyForced,
                value: L10n.subtitleModeOnlyForcedDescription
            )
            LabeledContent(
                L10n.none,
                value: L10n.subtitleModeNoneDescription
            )
            LabeledContent(
                L10n.smart,
                value: L10n.subtitleModeSmartDescription
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
