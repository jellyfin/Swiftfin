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

    var body: some View {
        switch log.type {
        case .system:
            TypedLogContentsView(log: log, parser: ServerLogParser()) { entry in
                LogEntryButton(
                    title: entry.source ?? .emptyDash,
                    logLevel: entry.type,
                    contents: entry.message,
                    timestamp: entry.timestamp,
                    action: { router.route(to: .serverLogEntry(entry: entry)) }
                )
            }
        case .directStream, .remux, .transcode, .other:
            TypedLogContentsView<ServerLogParser, EmptyView>(log: log, parser: nil) { _ in
                EmptyView()
            }
        }
    }
}

private struct TypedLogContentsView<Parser: LogParser, ParsedRow: View>: View where Parser.Element: Hashable {

    @Router
    private var router

    @StateObject
    private var viewModel: ServerLogContentsViewModel<Parser>

    @State
    private var showParsed = true

    let parsedRow: (Parser.Element) -> ParsedRow

    init(
        log: LogFile,
        parser: Parser?,
        @ViewBuilder parsedRow: @escaping (Parser.Element) -> ParsedRow
    ) {
        self.parsedRow = parsedRow
        _viewModel = StateObject(
            wrappedValue: ServerLogContentsViewModel(log: log, parser: parser)
        )
    }

    private var resolvedShowParsed: Bool {
        showParsed && viewModel.parsedLog != nil
    }

    private var isLoading: Bool {
        viewModel.parsedLog?.background.is(.loading) == true || viewModel.rawLog?.background.is(.loading) == true
    }

    @ViewBuilder
    private var contentView: some View {
        if resolvedShowParsed, let parserViewModel = viewModel.parsedLog {
            LogGrid(viewModel: parserViewModel) { entry in
                parsedRow(entry)
            }
        } else if let rawViewModel = viewModel.rawLog {
            LogGrid(viewModel: rawViewModel) { line in
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
        }
    }

    @ViewBuilder
    private var toolbarMenu: some View {
        Section {
            if viewModel.parsedLog != nil {
                Toggle(L10n.parsed, systemImage: "list.bullet.rectangle", isOn: $showParsed)
            }

            Menu {
                Picker(selection: $viewModel.sortOrder) {
                    ForEach(ItemSortOrder.allCases, id: \.self) { order in
                        Label(order.displayTitle, systemImage: order.systemImage).tag(order)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                Label(viewModel.sortOrder.displayTitle, systemImage: viewModel.sortOrder.systemImage)
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
            switch viewModel.state {
            case .initial:
                ProgressView()
            case .content:
                contentView
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.log)
        .navigationBarMenuButton(isLoading: isLoading) {
            toolbarMenu
        }
        .onFirstAppear {
            viewModel.refresh(force: false)
        }
        .refreshable {
            viewModel.refresh(force: true)
        }
    }
}

private struct LogGrid<Parser: LogParser, Content: View>: View where Parser.Element: Hashable {

    @ObservedObject
    var viewModel: PagingLogViewModel<Parser>
    @ViewBuilder
    let content: (Parser.Element) -> Content

    var body: some View {
        if viewModel.elements.isEmpty, !viewModel.hasNextPage {
            ContentUnavailableView(L10n.noActivity.localizedCapitalized, systemImage: "waveform.path.ecg")
        } else {
            CollectionVGrid(
                uniqueElements: viewModel.elements,
                id: \.self,
                layout: .columns(1)
            ) { element in
                content(element)
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                viewModel.getNextPage()
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
