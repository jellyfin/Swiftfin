//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import JellyfinAPI
import SwiftUI
import UIKit

struct ServerLogContentsView: View {

    @Router
    private var router

    let log: LogFile

    @StateObject
    private var viewModel: ServerLogContentsViewModel

    @State
    private var showParsed = true

    init(log: LogFile) {
        self.log = log
        _viewModel = StateObject(wrappedValue: ServerLogContentsViewModel(log: log))
    }

    private var resolvedShowParsed: Bool {
        showParsed && log.type == .system
    }

    private var isEmptyAndFinished: Bool {
        let count = resolvedShowParsed ? viewModel.entries.count : viewModel.lines.count
        return count == 0 && viewModel.isFinished
    }

    @ViewBuilder
    private var contentView: some View {
        if isEmptyAndFinished {
            ContentUnavailableView(L10n.noActivity.localizedCapitalized, systemImage: "waveform.path.ecg")
        } else if resolvedShowParsed {
            parsedGrid
        } else {
            rawList
        }
    }

    private var parsedGrid: some View {
        CollectionVGrid(
            uniqueElements: viewModel.entries,
            id: \.id,
            layout: .columns(1)
        ) { entry in
            ParsedServerEntry(entry: entry) {
                router.route(to: .serverLogEntry(entry: entry))
            }
        }
        .onReachedBottomEdge(offset: .offset(300)) {
            viewModel.loadNextPage()
        }
        .frame(maxWidth: .infinity)
    }

    private var rawList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.lines.indices, id: \.self) { idx in
                    Text(viewModel.lines[idx].isEmpty ? " " : viewModel.lines[idx])
                        .font(.system(.subheadline, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = viewModel.lines[idx]
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                }

                if !viewModel.isFinished {
                    Color.clear
                        .frame(height: 1)
                        .id(viewModel.lines.count)
                        .onAppear { viewModel.loadNextPage() }
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    @ViewBuilder
    private var toolbarMenu: some View {
        if log.type == .system {
            Section {
                Toggle(L10n.parsed, systemImage: "list.bullet.rectangle", isOn: $showParsed)
            }
        }

        Section {
            if let url = viewModel.url {
                Button {
                    router.route(to: .shareSheet(urls: [url]))
                } label: {
                    Label(L10n.share, systemImage: "square.and.arrow.up")
                }
            }

            if let webURL = viewModel.webURL {
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
            if viewModel.url == nil {
                ProgressView()
            } else {
                contentView
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.log)
        .navigationBarMenuButton {
            toolbarMenu
        }
        .onFirstAppear {
            viewModel.download(force: false)
        }
        .refreshable {
            viewModel.download(force: true)
        }
    }
}
