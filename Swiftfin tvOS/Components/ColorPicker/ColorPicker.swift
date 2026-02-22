//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import SwiftUI

struct ColorPicker: View {

    @State
    private var isPresented = false

    private let selection: Binding<Color>
    private let supportsOpacity: Bool
    private let title: String

    init(_ title: String, selection: Binding<Color>, supportsOpacity: Bool = false) {
        self.selection = selection
        self.supportsOpacity = supportsOpacity
        self.title = title
    }

    var body: some View {
        ChevronButton {
            isPresented = true
        } label: {
            LabeledContent(title) {
                Image(systemName: "circle.fill")
                    .foregroundStyle(selection.wrappedValue)
            }
        }
        ._alert(
            title,
            isPresented: $isPresented
        ) {
            StateAdapter(initialValue: selection.wrappedValue) { color in
                Self._Alert(value: color)
                    .backport
                    .onChange(of: isPresented) { _, newValue in
                        if !newValue {
                            selection.wrappedValue = color.wrappedValue
                        }
                    }
            }
        }
    }
}
