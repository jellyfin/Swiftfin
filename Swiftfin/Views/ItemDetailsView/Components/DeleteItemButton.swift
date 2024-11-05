//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemDetailsView {
    struct DeleteItemButton: View {
        @StateObject
        private var viewModel: DeleteItemViewModel

        @State
        private var showConfirmationDialog = false
        @State
        private var isPresentingEventAlert = false
        @State
        private var isPresentingFailedAlert = false
        @State
        private var error: JellyfinAPIError?

        private let onSuccess: () -> Void

        // MARK: - Initializer

        init(item: BaseItemDto, onSuccess: @escaping () -> Void) {
            _viewModel = StateObject(wrappedValue: DeleteItemViewModel(item: item))
            self.onSuccess = onSuccess
        }

        // MARK: - Body

        var body: some View {
            Button(role: .destructive) {
                showConfirmationDialog = true
            } label: {
                Text(L10n.delete)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            // TODO: Get better coloring / formatting?
            .foregroundStyle(.white)
            .listRowBackground(Color.red)
            .confirmationDialog(
                L10n.deleteItemConfirmationMessage,
                isPresented: $showConfirmationDialog,
                titleVisibility: .visible
            ) {
                Button(L10n.confirm, role: .destructive) {
                    viewModel.send(.delete)
                }
                Button(L10n.cancel, role: .cancel) {}
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    error = eventError
                    isPresentingEventAlert = true
                case .deleted:
                    if viewModel.item != nil {
                        isPresentingFailedAlert = true
                    }
                }
            }
            .alert(
                L10n.error,
                isPresented: $isPresentingEventAlert,
                presenting: error
            ) { _ in

            } message: { error in
                Text(error.localizedDescription)
            }
            .alert(
                L10n.taskFailed,
                isPresented: $isPresentingFailedAlert
            ) {
                Text(L10n.unknownError)
            }
        }
    }
}
