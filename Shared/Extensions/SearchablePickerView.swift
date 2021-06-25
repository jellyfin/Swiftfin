//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import SwiftUI

private struct SearchablePickerView<Selectable: Hashable>: View {
    @Environment(\.presentationMode)
    var presentationMode

    let options: [Selectable]
    let optionToString: (Selectable) -> String
    let label: String

    @State var text = ""
    @Binding var selected: Selectable

    var body: some View {
        VStack {
            SearchBar(text: $text)
            List(options.filter {
                guard !text.isEmpty else { return true }
                return optionToString($0).lowercased().contains(text.lowercased())
            }, id: \.self) { selectable in
                Button(action: {
                    selected = selectable
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(optionToString(selectable)).foregroundColor(Color.primary)
                        Spacer()
                        if selected == selectable {
                            Image(systemName: "checkmark").foregroundColor(.accentColor)
                        }
                    }
                }
            }.listStyle(GroupedListStyle())
        }
    }
}

struct SearchablePicker<Selectable: Hashable>: View {
    let label: String
    let options: [Selectable]
    let optionToString: (Selectable) -> String

    @Binding var selected: Selectable

    var body: some View {
        NavigationLink(destination: searchablePickerView()) {
            HStack {
                Text(label)
                Spacer()
                Text(optionToString(selected))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func searchablePickerView() -> some View {
        SearchablePickerView(options: options,
                             optionToString: optionToString,
                             label: label,
                             selected: $selected)
    }
}
