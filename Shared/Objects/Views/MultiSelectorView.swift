/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI

private struct MultiSelectionView<Selectable: Hashable>: View {
    let options: [Selectable]
    let optionToString: (Selectable) -> String
    let label: String

    @Binding var selected: [Selectable]

    var body: some View {
        List {
            ForEach(options, id: \.self) { selectable in
                Button(action: { toggleSelection(selectable: selectable) }) {
                    HStack {
                        Text(optionToString(selectable)).foregroundColor(Color.primary)
                        Spacer()
                        if selected.contains { $0 == selectable } {
                            Image(systemName: "checkmark").foregroundColor(.accentColor)
                        }
                    }
                }.tag(selectable)
            }
        }.listStyle(GroupedListStyle())
    }

    private func toggleSelection(selectable: Selectable) {
        if let existingIndex = selected.firstIndex(where: { $0 == selectable }) {
            selected.remove(at: existingIndex)
        } else {
            selected.append(selectable)
        }
    }
}

struct MultiSelector<Selectable: Hashable>: View {
    let label: String
    let options: [Selectable]
    let optionToString: (Selectable) -> String

    var selected: Binding<[Selectable]>

    private var formattedSelectedListString: String {
        ListFormatter.localizedString(byJoining: selected.wrappedValue.map { optionToString($0) })
    }

    var body: some View {
        NavigationLink(destination: multiSelectionView()) {
            HStack {
                Text(label)
                Spacer()
                Text(formattedSelectedListString)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func multiSelectionView() -> some View {
        MultiSelectionView(
            options: options,
            optionToString: optionToString,
            label: self.label,
            selected: selected
        )
    }
}
