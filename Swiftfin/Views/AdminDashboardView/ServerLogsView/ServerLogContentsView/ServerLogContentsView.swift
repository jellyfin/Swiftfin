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

    let log: LogFile

    @ViewBuilder
    var body: some View {
        switch log.type {
        case .system:
            ServerLogContentsBody(log: log, parser: ServerLogParser())
        case .directStream, .remux, .transcode:
            ServerLogContentsBody(log: log, parser: FFmpegLogParser())
        case .other:
            ServerLogContentsBody<ServerLogParser>(log: log, parser: nil)
        }
    }
}

private struct ServerLogContentsBody<Parser: LogParser>: View where Parser.Element == ServerLogEntry {

    @Router
    private var router

    @StateObject
    private var viewModel: ServerLogContentsViewModel<Parser>

    @State
    private var showParsed = true

    let log: LogFile

    init(log: LogFile, parser: Parser?) {
        self.log = log
        _viewModel = StateObject(wrappedValue: ServerLogContentsViewModel(log: log, parser: parser))
    }

    private var resolvedShowParsed: Bool {
        showParsed && viewModel.parsed != nil
    }

    @ViewBuilder
    private var contentView: some View {
        if resolvedShowParsed, let parsed = viewModel.parsed {
            ParsedReaderView(reader: parsed) { entry in
                router.route(to: .serverLogEntry(entry: entry))
            }
        } else if let raw = viewModel.raw {
            RawReaderView(reader: raw)
        }
    }

    @ViewBuilder
    private var toolbarMenu: some View {
        if viewModel.parsed != nil {
            Section {
                Toggle(L10n.parsed, systemImage: "list.bullet.rectangle", isOn: $showParsed)
            }
        }

        Section {
            Menu {
                Picker(selection: $viewModel.sortOrder) {
                    ForEach(ItemSortOrder.allCases, id: \.self) { order in
                        Text(order.displayTitle).tag(order)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                Label(viewModel.sortOrder.displayTitle, systemImage: "arrow.up.arrow.down")
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

private struct ParsedReaderView<Parser: LogParser>: View where Parser.Element == ServerLogEntry {

    @ObservedObject
    var reader: PagingLogViewModel<Parser>

    let onSelect: (ServerLogEntry) -> Void

    var body: some View {
        if reader.elements.isEmpty, !reader.hasNextPage {
            ContentUnavailableView(L10n.noActivity.localizedCapitalized, systemImage: "waveform.path.ecg")
        } else {
            CollectionVGrid(
                uniqueElements: reader.elements,
                id: \ServerLogEntry.id,
                layout: .columns(1)
            ) { entry in
                ServerLogContentsView.ParsedServerEntry(entry: entry) {
                    onSelect(entry)
                }
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                reader.getNextPage()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct RawReaderView: View {

    @ObservedObject
    var reader: PagingLogViewModel<RawLogParser>

    var body: some View {
        if reader.elements.isEmpty, !reader.hasNextPage {
            ContentUnavailableView(L10n.noActivity.localizedCapitalized, systemImage: "waveform.path.ecg")
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(reader.elements.indices, id: \.self) { idx in
                        let line = reader.elements[idx]
                        Text(line.isEmpty ? " " : line)
                            .font(.system(.subheadline, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = line
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                            }
                    }

                    if reader.hasNextPage {
                        Color.clear
                            .frame(height: 1)
                            .id(reader.elements.count)
                            .onAppear { reader.getNextPage() }
                    }
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}
