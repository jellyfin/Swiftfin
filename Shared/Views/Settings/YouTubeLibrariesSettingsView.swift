//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct YouTubeLibrariesSettingsView: View {

    @Default(.Customization.Library.youtubeLibraryIDs)
    private var youtubeLibraryIDs

    @StateObject
    private var viewModel = YouTubeLibrariesSettingsViewModel()

    private func binding(for id: String) -> Binding<Bool> {
        Binding {
            youtubeLibraryIDs.contains(id)
        } set: { isOn in
            if isOn {
                youtubeLibraryIDs.insert(id)
            } else {
                youtubeLibraryIDs.remove(id)
            }
        }
    }

    private var hasDetectedLibraries: Bool {
        viewModel.libraries.isNotEmpty
    }

    var body: some View {
        List {
            switch viewModel.state {
            case .initial, .loading:
                Section {
                    ProgressView()
                }
            case let .error(error):
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.localizedDescription)
                        Button(L10n.retry) {
                            Task { await viewModel.load() }
                        }
                    }
                }
            case .content:
                if hasDetectedLibraries {
                    Section {
                        ForEach(viewModel.libraries, id: \.id) { library in
                            Toggle(library.name, isOn: binding(for: library.id))
                                .disabled(!hasDetectedLibraries)
                        }
                    } footer: {
                        Text(L10n.youtubeLibrariesHelper)
                    }
                } else {
                    Section {
                        Toggle("YouTube (no libraries detected)", isOn: .constant(false))
                            .disabled(true)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.noYouTubeLibrariesDetected)
                                .font(.headline)
                            Text(L10n.noYouTubeLibrariesDetectedDescription)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(L10n.youtubeLibraries)
        .task {
            await viewModel.load()
        }
    }
}
