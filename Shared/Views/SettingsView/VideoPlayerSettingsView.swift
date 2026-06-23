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

    // MARK: - Audio Defaults

    @Default(.VideoPlayer.nightMode)
    private var nightMode
    @Default(.VideoPlayer.videoPlayerType)
    private var videoPlayerType

    // MARK: - Slider Defaults

    @Default(.VideoPlayer.Overlay.chapterSlider)
    private var chapterSlider
    @StoredValue(.User.previewImageScrubbing)
    private var previewImageScrubbing: PreviewImageScrubbingOption

    // MARK: - Supplement Defaults

    @Default(.VideoPlayer.supplements)
    private var supplements

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
        _viewModel =
            StateObject(wrappedValue: ServerUserAdminViewModel(user: Container.shared.currentUserSession()?.user.data ?? UserDto()))
    }

    private func updateConfiguration(_ modify: (inout UserConfiguration) -> Void) {
        guard viewModel.user.id != nil else { return }
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

            supplementSettings

            timestampSettings

            audioSettings

            subtitleSettings
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.videoPlayer.localizedCapitalized)
        .topBarTrailing {
            if viewModel.background.is(.updating) || viewModel.background.is(.refreshing) {
                ProgressView()
            }
        }
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
            JumpIntervalPicker(
                title: L10n.jumpBackwardLength,
                selection: $jumpBackwardLength
            )

            JumpIntervalPicker(
                title: L10n.jumpForwardLength,
                selection: $jumpForwardLength
            )

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
        .backport
        .onChange(of: barActionButtons) { _, newValue in
            let enabled = newValue.contains(.autoPlay) || menuActionButtons.contains(.autoPlay)
            updateConfiguration { $0.enableNextEpisodeAutoPlay = enabled }
        }
        .backport
        .onChange(of: menuActionButtons) { _, newValue in
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
                        .foregroundStyle(.secondary)
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

    // MARK: - Supplement Settings

    @ViewBuilder
    private var supplementSettings: some View {
        Section(L10n.supplements) {
            ChevronButton(L10n.supplements) {
                router.route(to: .supplementSelector(
                    selectedSupplementsBinding: $supplements
                ))
            }
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

        Section {
            PlatformPicker(L10n.nightMode, selection: $nightMode)
                .disabled(videoPlayerType == .native)
        } header: {
            Text(L10n.nightMode)
        } footer: {
            Text(
                videoPlayerType == .native
                    ? L10n.nightModeNativeUnsupported
                    : L10n.nightModeDescription
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
                SubtitlePlaybackMode.default.displayTitle,
                value: SubtitlePlaybackMode.default.description
            )

            LabeledContent(
                SubtitlePlaybackMode.always.displayTitle,
                value: SubtitlePlaybackMode.always.description
            )

            LabeledContent(
                SubtitlePlaybackMode.onlyForced.displayTitle,
                value: SubtitlePlaybackMode.onlyForced.description
            )

            LabeledContent(
                SubtitlePlaybackMode.none.displayTitle,
                value: SubtitlePlaybackMode.none.description
            )

            LabeledContent(
                SubtitlePlaybackMode.smart.displayTitle,
                value: SubtitlePlaybackMode.smart.description
            )
        }

        Section {
            ChevronButton(L10n.subtitleFont, content: subtitleFontName) {
                router.route(to: .fontPicker(selection: $subtitleFontName))
            }

            Stepper(L10n.subtitleSize, value: $subtitleSize, in: 1 ... 20, step: 1) {
                LabeledContent(L10n.subtitleSize) {
                    Text(subtitleSize.description)
                        .foregroundStyle(.secondary)
                }
            }

            ColorPicker(L10n.subtitleColor, selection: $subtitleColor, supportsOpacity: false)
        } footer: {
            // TODO: better wording
            Text(L10n.subtitlesDisclaimer)
        }
    }
}
