//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Allow optional binding

struct EnumPicker<EnumType: CaseIterable & Displayable & Hashable & RawRepresentable>: View {

    @Binding
    var selection: EnumType

    let title: String

    init(title: String, selection: Binding<EnumType>) {
        self.title = title
        self._selection = selection
    }

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(EnumType.allCases.asArray, id: \.hashValue) {
                Text($0.displayTitle).tag($0)
            }
        }
    }
}
