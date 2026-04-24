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

    private var url: URL? {
        viewModel.downloads[log]?.url
    }

    private var content: ServerLogContent? {
        viewModel.downloads[log]?.content
    }

    private var webURL: URL? {
        viewModel.downloads[log]?.webURL
    }

    private var filteredEntries: [ServerLogEntry] {
        guard let entries = content?.entries else { return [] }
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
    private var contentView: some View {
        if showParsed, log.type == .system {
            parsedLogView
        } else {
            RawServerLogView(text: content?.rawText ?? "")
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    @ViewBuilder
    private var toolbarMenu: some View {

        if log.type == .system {

            Section {

                Toggle(L10n.parsed, systemImage: "list.bullet.rectangle", isOn: $showParsed)

                if let content, !content.entries.isEmpty && showParsed {
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
            if let url {
                Button {
                    router.route(to: .shareSheet(urls: [url]))
                } label: {
                    Label(L10n.share, systemImage: "square.and.arrow.up")
                }
            }

            if let webURL {
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
            if content != nil {
                contentView
            } else {
                ProgressView()
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.log)
        .navigationBarMenuButton {
            toolbarMenu
        }
        .onFirstAppear {
            guard viewModel.downloads[log] == nil else { return }
            viewModel.download(log, force: false)
        }
        .refreshable {
            viewModel.download(log, force: true)
        }
    }
}
