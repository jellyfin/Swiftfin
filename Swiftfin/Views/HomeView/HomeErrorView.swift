//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension HomeView {

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
                        viewModel.refresh()
                    }
                    .frame(maxWidth: 300)
                    .frame(height: 50)
            }
            .offset(y: -50)
        }
    }
}
