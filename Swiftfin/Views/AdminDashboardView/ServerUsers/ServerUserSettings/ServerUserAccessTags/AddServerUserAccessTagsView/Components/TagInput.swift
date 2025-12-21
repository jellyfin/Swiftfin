//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AddServerUserAccessTagsView {

    struct TagInput: View {

        // MARK: - Element Variables

        @FocusState
        private var isTagFocused: Bool

        @Binding
        var access: Bool
        @Binding
        var tag: String

        let alreadyOnItem: Bool
        let existsOnServer: Bool

        // MARK: - Body

        var body: some View {
            Section(L10n.access) {
                Picker(L10n.access, selection: $access) {
                    Text(L10n.allowed).tag(true)
                    Text(L10n.blocked).tag(false)
                }
            } learnMore: {
                LabeledContent(
                    L10n.allowed,
                    value: L10n.accessTagAllowDescription
                )

                LabeledContent(
                    L10n.blocked,
                    value: L10n.accessTagBlockDescription
                )
            }

            Section {
                TextField(L10n.name, text: $tag)
                    .autocorrectionDisabled()
                    .focused($isTagFocused)
            } footer: {
                if tag.isEmpty {
                    Label(
                        L10n.required,
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                } else if alreadyOnItem {
                    Label(
                        L10n.accessTagAlreadyExists,
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .red))
                } else if existsOnServer {
                    Label(
                        L10n.existsOnServer,
                        systemImage: "checkmark.circle.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .green))
                } else {
                    Label(
                        L10n.willBeCreatedOnServer,
                        systemImage: "checkmark.seal.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .blue))
                }
            }
            .onFirstAppear {
                isTagFocused = true
            }
        }
    }
}
