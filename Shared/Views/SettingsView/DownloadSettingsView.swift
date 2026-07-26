//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import SwiftUI

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

    @State
    private var isPresentingClearConfirmation = false

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

            Section {
                Button(role: .destructive) {
                    isPresentingClearConfirmation = true
                } label: {
                    // swiftlint:disable:next hard_coded_display_string
                    Text("Clear Downloads")
                        .frame(maxWidth: .infinity)
                }
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
                #if os(iOS)
                    .listRowSeparator(.hidden)
                #endif
                    .fontWeight(.semibold)
                    .backport
                    .buttonStyle(.glassProminent.shadow(false))
                    .tint(.red)
                #if os(iOS)
                    .controlSize(.large)
                #endif
            }
        }
        .navigationTitle(L10n.downloads)
        .confirmationDialog(
            // swiftlint:disable:next hard_coded_display_string
            "Clear Downloads",
            isPresented: $isPresentingClearConfirmation,
            titleVisibility: .visible
        ) {
            // swiftlint:disable:next hard_coded_display_string
            Button("Clear Downloads", role: .destructive) {
                downloadManager.clearAll()
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            // swiftlint:disable:next hard_coded_display_string
            Text("This will remove all downloaded files from your device.")
        }
    }
}
