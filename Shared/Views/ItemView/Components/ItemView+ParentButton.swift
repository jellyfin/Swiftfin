//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ParentButton: View {

        @Router
        private var router

        let title: String
        let id: String

        var body: some View {
            Button {
                router.route(to: .item(id: id))
            } label: {
                Label {
                    Text(title)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "chevron.forward")
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            .foregroundStyle(.primary, .secondary)
            .labelStyle(.trailingIcon)
            .buttonStyle(.capsule)
            .controlSize(UIDevice.isTV ? .large : .regular)
        }
    }
}
