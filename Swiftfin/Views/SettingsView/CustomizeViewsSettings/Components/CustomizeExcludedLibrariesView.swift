//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CustomizeExcludedLibrariesView: View {

    @Default(.Customization.Library.excludeLibraries)
    private var excludedLibraries: [ExcludedLibrary]

    @State
    private var isEditing: Bool = false
    @State
    private var localExcludedLibraries: [ExcludedLibrary]

    init() {
        _localExcludedLibraries = State(initialValue: Defaults[.Customization.Library.excludeLibraries])
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(localExcludedLibraries) { library in
                    HStack {
                        Text(library.name)

                        Spacer()

                        if isEditing {
                            Button(action: {
                                removeLibrary(library)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Excluded Libraries")
        .toolbar {
            Button(action: {
                isEditing.toggle()
            }) {
                Text(isEditing ? "Done" : "Edit")
            }
        }
    }

    private func removeLibrary(_ library: ExcludedLibrary) {
        if let index = localExcludedLibraries.firstIndex(of: library) {
            localExcludedLibraries.remove(at: index)
            Defaults[.Customization.Library.excludeLibraries] = localExcludedLibraries
        }
    }
}
