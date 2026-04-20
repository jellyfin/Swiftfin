//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Engine
import JellyfinAPI
import SwiftUI
import UniformTypeIdentifiers

struct ItemSubtitleUploadView: View {

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    var viewModel: ItemSubtitlesViewModel

    @Router
    private var router

    @State
    private var isForced = false
    @State
    private var isHearingImpaired = false
    @State
    private var selectedFile: URL?

    var body: some View {
        Form {
            Section(L10n.options) {
                CulturePicker(L10n.language, threeLetterISOLanguageName: $viewModel.language)

                Toggle(L10n.forced, isOn: $isForced)
                Toggle(L10n.hearingImpaired, isOn: $isHearingImpaired)
            }

            Section(L10n.file) {
                Text(selectedFile?.lastPathComponent ?? L10n.none)
                    .foregroundStyle(.secondary)
            }

            Section {
                StateAdapter(initialValue: false) { isPresentingFileUpload in
                    Button(selectedFile == nil ? L10n.uploadFile : L10n.replaceSubtitle) {
                        isPresentingFileUpload.wrappedValue = true
                    }
                    .buttonStyle(.primary)
                    .foregroundStyle(accentColor.overlayColor, accentColor)
                    .fileImporter(
                        isPresented: isPresentingFileUpload,
                        allowedContentTypes: SubtitleFormat.allCases.filter(\.isText).compactMap(\.utType)
                    ) { result in
                        selectedFile = try? result.get()
                    }
                }
            }
        }
        .navigationTitle(L10n.subtitle)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .onReceive(viewModel.events) { event in
            switch event {
            case .deleted:
                break
            case .uploaded:
                router.dismiss()
            }
        }
        .errorMessage($viewModel.error)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.is(.updating) {
                ProgressView()
            } else {
                Button(L10n.save) {
                    guard let selectedFile else { return }
                    viewModel.upload(
                        file: selectedFile,
                        isForced: isForced,
                        isHearingImpaired: isHearingImpaired
                    )
                }
                .buttonStyle(.toolbarPill)
                .disabled(selectedFile == nil)
            }
        }
    }
}
