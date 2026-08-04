//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import JellyfinAPI
import SwiftUI

extension ItemView.ActionButtons {

    struct Delete: View {

        @EnvironmentObject
        private var provider: ItemContentGroupProvider

        var body: some View {
            Content(item: provider.item)
        }

        private struct Content: View {

            @StateObject
            private var viewModel: ItemEditorViewModel

            @Router
            private var router

            init(item: BaseItemDto) {
                self._viewModel = StateObject(wrappedValue: ItemEditorViewModel(item: item))
            }

            var body: some View {
                StateAdapter(initialValue: false) { isPresentingConfirmation in
                    Button(role: .destructive) {
                        isPresentingConfirmation.wrappedValue = true
                    } label: {
                        ItemView.ActionButtonLabel(.delete)
                    }
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.primary, .secondary)
                    .confirmationDialog(
                        L10n.deleteItemConfirmationMessage,
                        isPresented: isPresentingConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(
                            L10n.confirm,
                            role: .destructive,
                            action: viewModel.delete
                        )

                        Button(L10n.cancel, role: .cancel) {}
                    }
                    .onNotification(.didDeleteItem) { _ in
                        UIDevice.feedback(.success)
                        router.dismiss()
                    }
                    .errorMessage($viewModel.error)
                }
            }
        }
    }
}
