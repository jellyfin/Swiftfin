//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import UIKit

// TODO: Fix updating view with Binding
struct FontPickerView: View {
    
    @Binding
    private var selection: String
    
    @State
    private var updateSelection: [String]
    
    init(selection: Binding<String>) {
        self._selection = selection
        self.updateSelection = [selection.wrappedValue]
    }
    
    var body: some View {
        SelectorView(
            selection: $updateSelection,
            allItems: UIFont.familyNames,
            type: .single
        )
        .label { fontFamily in
            Text(fontFamily)
                .foregroundColor(.white)
                .font(.custom(fontFamily, size: 18))
        }
        .onChange(of: updateSelection) { newValue in
            selection = updateSelection[0]
        }
    }
}
