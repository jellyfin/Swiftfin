//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import JellyfinAPI
import SwiftUI

struct LayoutLibraryPickerView: View {

    @Injected(\.currentUserSession)
    private var userSession

    @Router
    private var router

    @State
    private var libraries: [BaseItemDto] = []
    @State
    private var error: ErrorMessage?
    @State
    private var isLoading = true

    private let selectionID: String?
    private let onSelect: (BaseItemDto?) -> Void

    init(
        selectionID: String?,
        onSelect: @escaping (BaseItemDto?) -> Void
    ) {
        self.selectionID = selectionID
        self.onSelect = onSelect
    }

    @ContentBuilder
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                ErrorView(error: error)
            } else {
                libraryList
            }
        }
        .navigationTitle(L10n.libraries)
        .refreshable {
            await getLibraries()
        }
        .task {
            await getLibraries()
        }
    }

    @ContentBuilder
    private var libraryList: some View {
        List {
            libraryButton(nil)

            if libraries.isEmpty {
                ContentUnavailableView(
                    L10n.noItems.localizedCapitalized,
                    systemImage: "rectangle.stack"
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(libraries, id: \.id) { library in
                    libraryButton(library)
                }
            }
        }
    }

    private func libraryButton(_ library: BaseItemDto?) -> some View {
        let isSelected = selectionID == library?.id

        return Button {
            onSelect(library)
            router.dismiss()
        } label: {
            HStack {
                Image(systemName: library?.systemImage ?? "rectangle.stack.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                Text(library?.displayTitle ?? L10n.all)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    ListRowCheckbox()
                        .isEditing(true)
                        .isSelected(true)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @MainActor
    private func getLibraries() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        guard let userSession else {
            libraries = []
            error = ErrorMessage(L10n.signIn)
            return
        }

        do {
            let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
            async let userViews = userSession.client.send(
                Paths.getUserViews(parameters: parameters)
            )
            async let currentUser = userSession.client.send(Paths.getCurrentUser)

            let excludedLibraryIDs = try await currentUser.value.configuration?.myMediaExcludes ?? []

            try Task.checkCancellation()

            libraries = try await (userViews.value.items ?? [])
                .coalesced(property: \.collectionType, with: .folders)
                .intersecting(
                    CollectionType.supportedCases.filter { $0 != .livetv },
                    using: \.collectionType
                )
                .subtracting(excludedLibraryIDs, using: \.id)
                .filter { $0.id?.isEmpty == false }
                .map { item in
                    if item.type == .userView, item.collectionType == .folders {
                        return item.mutating(\.type, with: .folder)
                    }

                    return item
                }
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }

            libraries = []
            self.error = ErrorMessage(error.localizedDescription)
        }
    }
}
