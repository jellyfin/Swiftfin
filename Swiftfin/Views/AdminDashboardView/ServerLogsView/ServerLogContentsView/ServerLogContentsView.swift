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

    private var rowCount: Int {
        resolvedShowParsed ? viewModel.entries.count : viewModel.lines.count
    }

    private var isEmptyAndFinished: Bool {
        rowCount == 0 && viewModel.isFinished
    }

    @ViewBuilder
    private var contentView: some View {
        if isEmptyAndFinished {
            ContentUnavailableView(L10n.noActivity.localizedCapitalized, systemImage: "waveform.path.ecg")
        } else {
            CollectionVGrid(
                count: rowCount,
                layout: .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
            ) { idx in
                if resolvedShowParsed {
                    parsedRow(viewModel.entries[idx])
                } else {
                    rawRow(viewModel.lines[idx])
                }
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                viewModel.loadNextPage()
            }
            // Toggling parsed/raw flips the cell builder, but the int IDs are identical
            // across modes — `.id` forces a full rebuild so cells re-bind to the new closure.
            .id(resolvedShowParsed)
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    @ViewBuilder
    private func parsedRow(_ entry: ServerLogEntry) -> some View {
        ChevronButton(action: {
            router.route(to: .serverLogEntry(entry: entry))
        }) {
            LabeledContent {
                EmptyView()
            } label: {
                ParsedServerLogRow(entry: entry)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func rawRow(_ line: String) -> some View {
        Button {
            UIPasteboard.general.string = line
        } label: {
            Text(line.isEmpty ? " " : line)
                .font(.system(.subheadline, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
