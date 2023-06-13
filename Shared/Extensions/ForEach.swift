//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ForEach where Content: View {

    @ViewBuilder
    static func `let`(
        _ data: Data?,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) -> some View {
        if let data {
            ForEach(data, id: id, content: content)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    static func `let`(_ data: Data?, @ViewBuilder content: @escaping (Data.Element) -> Content) -> some View where ID == Data.Element.ID,
    Data.Element: Identifiable {
        if let data {
            ForEach(data, content: content)
        } else {
            EmptyView()
        }
    }
}
