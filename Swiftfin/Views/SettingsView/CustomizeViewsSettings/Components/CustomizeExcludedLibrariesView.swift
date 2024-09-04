//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import OrderedCollections
import SwiftUI

struct CustomizeExcludedLibrariesView: View {
    @Default(.Customization.Library.excludeLibraries)
    private var inactiveLibraries

    @StateObject
    private var viewModel = MediaViewModel()

    @State
    private var isEditing: Bool = false
    @State
    private var allLibraries: [ExcludedLibrary] = []

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Included Libraries")) {
                    if activeLibraries.isEmpty {
                        Text("None")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(activeLibraries, id: \.id) { library in
                            Button {
                                if !isEditing {
                                    withAnimation {
                                        excludeLibrary(library)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(library.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if !isEditing {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Excluded Libraries")) {
                    if inactiveLibraries.isEmpty {
                        Text("None")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(inactiveLibraries, id: \.id) { library in
                            Button {
                                if !isEditing {
                                    withAnimation {
                                        includeLibrary(library)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(library.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if !isEditing {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .animation(.default, value: inactiveLibraries)
        }
        .navigationTitle("Customize Libraries")
        .onAppear {
            loadLibraries()
        }
    }

    private var activeLibraries: [ExcludedLibrary] {
        allLibraries.filter { !inactiveLibraries.contains($0) }
    }

    private func loadLibraries() {
        Task {
            allLibraries = await viewModel.sourceLibraries()
        }
    }

    private func includeLibrary(_ library: ExcludedLibrary) {
        if let index = inactiveLibraries.firstIndex(where: { $0.id == library.id }) {
            inactiveLibraries.remove(at: index)
            Defaults[.Customization.Library.excludeLibraries] = inactiveLibraries
        }
    }

    private func excludeLibrary(_ library: ExcludedLibrary) {
        if !inactiveLibraries.contains(where: { $0.id == library.id }) {
            inactiveLibraries.append(library)
            Defaults[.Customization.Library.excludeLibraries] = inactiveLibraries
        }
    }
}
