//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Engine
import FactoryKit
import SwiftUI

// TODO: wifi/cellular downloading
// TODO: retention of downloads

struct DownloadSettingsView: View {

    @Default(.Downloads.isChaptersEnabled)
    private var isChaptersEnabled
    @Default(.Downloads.isLyricsEnabled)
    private var isLyricsEnabled
    @Default(.Downloads.isSubtitlesEnabled)
    private var isSubtitlesEnabled
    @Default(.Downloads.isTrickplayEnabled)
    private var isTrickplayEnabled

    @Injected(\.downloadManager)
    private var downloadManager

    var body: some View {
        Form(systemImage: "arrow.down.circle") {
            Section(L10n.video) {
                Toggle(L10n.chapters, isOn: $isChaptersEnabled)

                Toggle(L10n.subtitles, isOn: $isSubtitlesEnabled)

                Toggle(L10n.trickplays, isOn: $isTrickplayEnabled)

                // TODO: default bitrate for transcoded downloads
                // CaseIterablePicker(L10n.maximumBitrate, selection: $videoMaxBitrate)
            }

            Section(L10n.audio) {
                // TODO: enable with audio downloads
                Toggle(L10n.lyrics, isOn: $isLyricsEnabled)
                    .disabled(true)

                // TODO: default bitrate for transcoded downloads
                // CaseIterablePicker(L10n.maximumBitrate, selection: $audioMaxBitrate)
            }

            // TODO: Make a DownloadQueueView and move this button there
            Section(L10n.reset) {
                StateAdapter(initialValue: false) { isPresentingClearConfirmation in
                    Button(role: .destructive) {
                        isPresentingClearConfirmation.wrappedValue = true
                    } label: {
                        Text(L10n.clearDownloads)
                            .frame(maxWidth: .infinity)
                    }
                    .listRowInsets(.zero)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .fontWeight(.semibold)
                    .backport
                    .buttonStyle(.glassProminent.shadow(false))
                    .tint(.red)
                    .controlSize(.large)
                    .confirmationDialog(
                        L10n.clearDownloads,
                        isPresented: isPresentingClearConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(L10n.clearDownloads, role: .destructive) {
                            downloadManager.clearAll()
                        }
                        Button(L10n.cancel, role: .cancel) {}
                    } message: {
                        Text(L10n.clearDownloadsMessage)
                    }
                }
            }
        }
        .navigationTitle(L10n.downloads)
    }
}
