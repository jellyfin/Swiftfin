//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct FontPickerView: View {

    @Binding
    private var selection: String

    @State
    private var updateSelection: String

    init(selection: Binding<String>) {
        self._selection = selection
        self.updateSelection = selection.wrappedValue
    }

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "character.textbox")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                ForEach(UIFont.familyNames, id: \.self) { fontFamily in
                    Button {
                        selection = fontFamily
                        updateSelection = fontFamily
                    } label: {
                        HStack {
                            Text(fontFamily)
                                .font(.custom(fontFamily, size: 28))

                            Spacer()

                            if updateSelection == fontFamily {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                    }
                }
            }
    }
}
