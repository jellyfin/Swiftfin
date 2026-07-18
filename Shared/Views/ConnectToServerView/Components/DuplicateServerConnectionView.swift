//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ConnectToServerView {

    struct DuplicateServerConnectionView: PlatformView {

        @Environment(\.dismiss)
        private var dismiss

        @Namespace
        private var namespace

        let server: ServerState
        let action: () -> Void

        var iOSView: some View {
            Form {
                Section {
                    Text(L10n.duplicateServerConnectionMessage(server.name))
                        .font(.callout)
                }

                Section {
                    LabeledContent(
                        L10n.server,
                        value: server.name
                    )

                    LabeledContent(
                        L10n.url,
                        value: server.currentURL.absoluteString
                    )
                } header: {
                    Text(L10n.connection)
                } footer: {
                    Text(L10n.duplicateServerConnectionFooter)
                }

                Button(action: action) {
                    Text(L10n.add)
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
                    .tint(.jellyfinPurple)
                #if os(iOS)
                    .controlSize(.large)
                #endif
            }
            .backport
            .toolbarTitleDisplayMode(.inline)
            .navigationTitle(L10n.connection)
            .navigationBarCloseButton {
                dismiss()
            }
        }

        var tvOSView: some View {
            VStack {
                Text(L10n.duplicateServerConnectionMessage(server.name))
                    .font(.callout)
                    .multilineTextAlignment(.center)

                VStack {
                    LabeledContent(
                        L10n.server,
                        value: server.name
                    )

                    LabeledContent(
                        L10n.url,
                        value: server.currentURL.absoluteString
                    )
                }

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        AlternateLayoutView {
                            Color.clear
                                .aspectRatio(3.5, contentMode: .fit)
                                .frame(height: 40)
                        } content: {
                            Text(L10n.close)
                        }
                    }

                    Button(action: action) {
                        AlternateLayoutView {
                            Color.clear
                                .aspectRatio(3.5, contentMode: .fit)
                                .frame(height: 40)
                        } content: {
                            Text(L10n.add)
                        }
                    }
                }
                .focusSection()
            }
        }
    }
}
