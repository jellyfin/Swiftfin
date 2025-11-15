//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI
import UniformTypeIdentifiers

struct ItemSubtitleUploadView: View {

    // MARK: - Router

    @Router
    private var router

    // MARK: - Accent Color

    @Default(.accentColor)
    private var accentColor

    // MARK: - ViewModel

    @ObservedObject
    private var viewModel: SubtitleEditorViewModel

    // MARK: - Supported Subtitles for Upload

    private let validSubtitleFormats = SubtitleFormat.allCases.filter(\.isText).compactMap(\.utType)

    // MARK: - File Picker States

    @State
    private var isPresentingFileUpload = false

    // MARK: - Subtitle Data

    @State
    private var subtitleFile: URL?
    @State
    private var subtitleData: Data?
    @State
    private var subtitleFormat: SubtitleFormat?

    // MARK: - Subtitle Properties

    /// Default to user's language
    @State
    private var language: String? = Locale.current.language.languageCode?.identifier(.alpha3)
    @State
    private var isForced = false
    @State
    private var isHearingImpaired = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(viewModel: SubtitleEditorViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.subtitle)
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(viewModel.events) { event in
                switch event {
                case .deleted:
                    return
                case .uploaded:
                    router.dismiss()
                case let .error(eventError):
                    error = eventError
                }
            }
            .errorMessage($error)
            .navigationBarCloseButton {
                router.dismiss()
            }
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.updating) {
                    Button(L10n.cancel, role: .cancel) {
                        viewModel.send(.cancel)
                    }
                    .buttonStyle(.toolbarPill)
                } else {
                    Button(L10n.save) {
                        uploadSubtitle()
                    }
                    .buttonStyle(.toolbarPill)
                    .disabled(subtitleData == nil)
                }
            }
            .fileImporter(
                isPresented: $isPresentingFileUpload,
                allowedContentTypes: validSubtitleFormats,
                onCompletion: selectSubtitleFile
            )
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        Form {
            Section(L10n.options) {
                CulturePicker(L10n.language, threeLetterISOLanguageName: $language)

                Toggle(L10n.forced, isOn: $isForced)
                Toggle(L10n.hearingImpaired, isOn: $isHearingImpaired)
            }

            Section(L10n.file) {
                Text(subtitleFile?.lastPathComponent ?? L10n.noItemSelected)
                    .foregroundStyle(.secondary)
            }

            Section {
                ListRowButton(subtitleData == nil ? L10n.uploadFile : L10n.replaceSubtitle) {
                    isPresentingFileUpload = true
                }
                .foregroundStyle(accentColor.overlayColor, accentColor)
            }
        }
    }

    // MARK: - Select Subtitle File

    private func selectSubtitleFile(_ result: Result<URL, Error>) {
        do {
            let fileURL = try result.get()
            self.subtitleFile = fileURL

            if let format = SubtitleFormat(url: fileURL) {
                self.subtitleFormat = format
                self.subtitleData = try Data(contentsOf: fileURL)
            } else {
                error = ErrorMessage(L10n.invalidFormat)
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Upload Subtitle

    private func uploadSubtitle() {
        guard let subtitleData = subtitleData,
              let subtitleFormat = subtitleFormat
        else {
            error = ErrorMessage(L10n.noItemSelected)
            return
        }

        let encodedData = subtitleData.base64EncodedString()

        if let language {
            let subtitle = UploadSubtitleDto(
                data: encodedData,
                format: subtitleFormat.fileExtension,
                isForced: isForced,
                isHearingImpaired: isHearingImpaired,
                language: language
            )

            viewModel.send(.upload(subtitle))
        } else {
            error = ErrorMessage(L10n.noItemSelected)
        }
    }
}
