//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SettingsViewFormSection<Content: View, Header: View, Footer: View>: View {
    let header: () -> Header
    let footer: () -> Footer
    let content: () -> Content

    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.content = content
        self.header = header
        self.footer = footer
    }

    var body: some View {
        Section {
            content()
                .font(.body)
        } header: {
            header()
                .padding(.top, 15)
                .font(.subheadline)
        } footer: {
            footer()
                .font(.caption2)
        }
    }
}

extension SettingsViewFormSection where Header == EmptyView, Footer == EmptyView {
    init(@ViewBuilder content: @escaping () -> Content) {
        self.init(content: content, header: { EmptyView() }, footer: { EmptyView() })
    }
}

extension SettingsViewFormSection where Header == EmptyView {
    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.init(content: content, header: { EmptyView() }, footer: footer)
    }
}

extension SettingsViewFormSection where Footer == EmptyView {
    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder header: @escaping () -> Header
    ) {
        self.init(content: content, header: header, footer: { EmptyView() })
    }
}
