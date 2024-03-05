//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ErrorView<_Error: Error>: View {

    let error: _Error

    private var onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(Color.red)

            Text(error.localizedDescription)
                .frame(minWidth: 50, maxWidth: 240)
                .multilineTextAlignment(.center)

            PrimaryButton(title: L10n.retry)
                .onSelect(onRetry)
                .frame(maxWidth: 300)
                .frame(height: 50)
        }
    }
}

extension ErrorView {

    init(error: _Error) {
        self.init(
            error: error,
            onRetry: {}
        )
    }

    func onRetry(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onRetry, with: action)
    }
}

extension HomeView {

    // TODO: make a general component that takes a generic `Error` and action
    struct ErrorView: View {

        @ObservedObject
        var viewModel: HomeViewModel

        let errorMessage: ErrorMessage

        var body: some View {
            VStack(spacing: 5) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(width: 100, height: 100)
                        .scaleEffect(2)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(Color.red)
                        .frame(width: 100, height: 100)
                }

                if let code = errorMessage.code {
                    Text("\(code)")
                }

                Text(errorMessage.message)
                    .frame(minWidth: 50, maxWidth: 240)
                    .multilineTextAlignment(.center)

                PrimaryButton(title: L10n.retry)
                    .onSelect {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                    .frame(maxWidth: 300)
                    .frame(height: 50)
            }
            .offset(y: -50)
        }
    }
}
