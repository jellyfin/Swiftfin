//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct AnyPickerStyle {

    var style: any PickerStyle

    init(_ style: some PickerStyle) {
        self.style = style
    }
}

extension View {
    func pickerStyle(_ style: AnyPickerStyle) -> some View {
        func project(_ style: some PickerStyle) -> AnyView {
            AnyView(self.pickerStyle(style))
        }
        return _openExistential(style.style, do: project)
    }
}
