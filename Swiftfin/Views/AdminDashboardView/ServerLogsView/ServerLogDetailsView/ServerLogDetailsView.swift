//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI
import UIKit

struct ServerLogDetailsView: View {

    @Router
    private var router

    let log: LogFile

    @ObservedObject
    var viewModel: ServerLogsViewModel

    @State
    private var showParsed = true
    @State
    private var levelFilter: ServerLogEntry.Level?

    private var download: ServerLogDownload? {
        viewModel.downloads[log]
    }

    private var filteredEntries: [ServerLogEntry] {
        guard let entries = download?.content?.entries else { return [] }
        guard let levelFilter else { return entries }

        return entries.filter {
            $0.level == levelFilter
        }
    }

    @ViewBuilder
    private var parsedLogView: some View {
        if filteredEntries.isEmpty {
            ContentUnavailableView(L10n.noActivity.localizedCapitalized, systemImage: "waveform.path.ecg")
        } else {
            List(filteredEntries) { entry in
                ChevronButton(action: {
                    router.route(to: .serverLogEntry(entry: entry))
                }) {
                    LabeledContent {
                        EmptyView()
                    } label: {
                        ParsedServerLogRow(entry: entry)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private var rawLogView: some View {
        if let rawText = download?.content?.rawText, rawText.isNotEmpty {
            RawServerLogView(text: rawText)
                .ignoresSafeArea(.container, edges: .bottom)
        } else {
            ContentUnavailableView(L10n.noActivity.localizedCapitalized, systemImage: "waveform.path.ecg")
        }
    }

    @ViewBuilder
    private var toolbarMenu: some View {
        if log.type == .system {
            Section {
                Toggle(L10n.parsed, systemImage: "list.bullet.rectangle", isOn: $showParsed)

                if let entries = download?.content?.entries, entries.isNotEmpty, showParsed {
                    Picker(selection: $levelFilter) {
                        Label(L10n.all, systemImage: "line.3.horizontal")
                            .tag(nil as ServerLogEntry.Level?)

                        ForEach(ServerLogEntry.Level.allCases, id: \.self) { level in
                            Label(level.displayTitle, systemImage: level.systemImage)
                                .tag(level as ServerLogEntry.Level?)
                        }
                    } label: {
                        Text(L10n.level)
                        Text(levelFilter?.displayTitle ?? L10n.all)
                        Image(systemName: levelFilter?.systemImage ?? "line.3.horizontal")
                    }
                    .pickerStyle(.menu)
                }
            }
        }

        Section {
            if let url = download?.url {
                Button {
                    router.route(to: .shareSheet(urls: [url]))
                } label: {
                    Label(L10n.share, systemImage: "square.and.arrow.up")
                }
            }

            if let webURL = download?.webURL {
                Button {
                    UIApplication.shared.open(webURL)
                } label: {
                    Label(L10n.openInBrowser, systemImage: "safari")
                }
            }
        }
    }

    var body: some View {
        ZStack {
            if download?.content == nil {
                ProgressView()
            } else if showParsed, log.type == .system {
                parsedLogView
            } else {
                rawLogView
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.log)
        .navigationBarMenuButton {
            toolbarMenu
        }
        .onFirstAppear {
            viewModel.download(log, force: false)
        }
        .refreshable {
            viewModel.download(log, force: true)
        }
    }
}
