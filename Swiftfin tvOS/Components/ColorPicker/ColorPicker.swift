//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// tvOS Color Picker
/// Mirrors iOS's APIs so `ColorPicker` can be used in shared views without needing special consideration for tvOS
struct ColorPicker: View {

    @Environment(\.router)
    private var router

    private let title: String
    private let selection: Binding<Color>
    private let supportsOpacity: Bool

    init(_ title: String, selection: Binding<Color>, supportsOpacity: Bool = false) {
        self.title = title
        self.selection = selection
        self.supportsOpacity = supportsOpacity
    }

    var body: some View {
        ChevronButton(title) {
            router.route(
                to: .colorPicker(
                    title: title,
                    selection: selection,
                    supportsOpacity: supportsOpacity
                )
            )
        } icon: {
            EmptyView()
        } subtitle: {
            Circle()
                .fill(selection.wrappedValue)
                .frame(width: 30, height: 30)
        }
    }
}
