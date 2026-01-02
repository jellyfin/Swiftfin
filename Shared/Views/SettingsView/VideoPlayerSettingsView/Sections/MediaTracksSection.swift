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

struct TrackConfigurationSection: View {

    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize
    @Default(.VideoPlayer.Subtitle.subtitleColor)
    private var subtitleColor

    @Router
    private var router

    @StateObject
    private var viewModel = ServerUserAdminViewModel()

    // MARK: - Bindings

    private var audioLanguageBinding: Binding<String?> {
        Binding(
            get: { viewModel.user.configuration?.audioLanguagePreference },
            set: { newValue in
                var configuration = viewModel.user.configuration ?? UserConfiguration()
                configuration.audioLanguagePreference = newValue
                viewModel.updateConfiguration(configuration)
            }
        )
    }

    private var subtitleLanguageBinding: Binding<String?> {
        Binding(
            get: { viewModel.user.configuration?.subtitleLanguagePreference },
            set: { newValue in
                var configuration = viewModel.user.configuration ?? UserConfiguration()
                configuration.subtitleLanguagePreference = newValue
                viewModel.updateConfiguration(configuration)
            }
        )
    }

    private var subtitleModeBinding: Binding<SubtitlePlaybackMode> {
        Binding(
            get: { viewModel.user.configuration?.subtitleMode ?? .default },
            set: { newValue in
                var configuration = viewModel.user.configuration ?? UserConfiguration()
                configuration.subtitleMode = newValue
                viewModel.updateConfiguration(configuration)
            }
        )
    }

    private var playDefaultAudioTrackBinding: Binding<Bool> {
        Binding(
            get: { viewModel.user.configuration?.isPlayDefaultAudioTrack ?? true },
            set: { newValue in
                var configuration = viewModel.user.configuration ?? UserConfiguration()
                configuration.isPlayDefaultAudioTrack = newValue
                viewModel.updateConfiguration(configuration)
            }
        )
    }

    private var rememberAudioSelectionsBinding: Binding<Bool> {
        Binding(
            get: { viewModel.user.configuration?.isRememberAudioSelections ?? true },
            set: { newValue in
                var configuration = viewModel.user.configuration ?? UserConfiguration()
                configuration.isRememberAudioSelections = newValue
                viewModel.updateConfiguration(configuration)
            }
        )
    }

    private var rememberSubtitleSelectionsBinding: Binding<Bool> {
        Binding(
            get: { viewModel.user.configuration?.isRememberSubtitleSelections ?? true },
            set: { newValue in
                var configuration = viewModel.user.configuration ?? UserConfiguration()
                configuration.isRememberSubtitleSelections = newValue
                viewModel.updateConfiguration(configuration)
            }
        )
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        audioSection
        subtitleSection
    }

    @ViewBuilder
    private var audioSection: some View {
        Section(L10n.audio) {

            CulturePicker(L10n.language, threeLetterISOLanguageName: audioLanguageBinding)

            Toggle("Play default", isOn: playDefaultAudioTrackBinding)

            Toggle("Remember track selection", isOn: rememberAudioSelectionsBinding)

        } footer: {
            Text("All settings are saved to the Jellyfin Server and may impact your configuration for other clients.")
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

    @ViewBuilder
    private var subtitleSection: some View {
        Section(L10n.subtitles) {

            CulturePicker(L10n.language, threeLetterISOLanguageName: subtitleLanguageBinding)

            #if os(iOS)
            Picker("Subtitle mode", selection: subtitleModeBinding)
            #else
            ListRowMenu("Subtitle mode", selection: subtitleModeBinding)
            #endif

            Toggle("Remember track selection", isOn: rememberSubtitleSelectionsBinding)

        } footer: {
            Text("All settings are saved to the Jellyfin Server and may impact your configuration for other clients.")
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
            BasicStepper(
                L10n.subtitleSize,
                value: $subtitleSize,
                range: 1 ... 20,
                step: 1
            )

            ColorPicker(selection: $subtitleColor, supportsOpacity: false) {
                Text(L10n.subtitleColor)
            }
            #endif
        } footer: {
            Text(L10n.subtitlesDisclaimer)
        }
    }
}
