//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LayoutLibraryPickerView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = PagingLibraryViewModel(library: UserViewLibrary())

    private let selectionID: String?
    private let onSelect: (BaseItemDto?) -> Void

    init(
        selectionID: String?,
        onSelect: @escaping (BaseItemDto?) -> Void
    ) {
        self.selectionID = selectionID
        self.onSelect = onSelect
    }

    private var libraries: [BaseItemDto] {
        viewModel.elements.compactMap { element in
            guard case let .userView(item) = element,
                  item.snapshot.collectionType != .livetv
            else { return nil }

            var library = item.snapshot
            library.collectionType = library.collectionType ?? .folders
            if library.type == .userView, library.collectionType == .folders {
                library.type = .folder
            }
            return library
        }
    }

    @ContentBuilder
    var body: some View {
        Group {
            switch viewModel.state {
            case .initial, .refreshing:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .content:
                libraryList

            case .error:
                viewModel.error.map(ErrorView.init)
            }
        }
        .navigationTitle(L10n.libraries)
        .refreshable {
            viewModel.error = nil
            await viewModel.refresh()
        }
        .onFirstAppear {
            viewModel.refresh()
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
            }

            ForEach(libraries, id: \.id) { library in
                libraryButton(library)
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
                Label(
                    library?.displayTitle ?? L10n.all,
                    systemImage: library?.systemImage ?? "rectangle.stack.fill"
                )
                .labelStyle(.listRow)
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
        .foregroundStyle(.primary, .secondary)
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
