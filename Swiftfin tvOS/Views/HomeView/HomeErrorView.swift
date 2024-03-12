//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: make general `ErrorView` like iOS

extension HomeView {

    struct ErrorView: View {

        @ObservedObject
        var viewModel: HomeViewModel

        let errorMessage: ErrorMessage

        var body: some View {
            VStack {
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

//                Text("\(errorMessage.code)")

                Text(errorMessage.message)
                    .frame(minWidth: 50, maxWidth: 240)
                    .multilineTextAlignment(.center)

                Button {
//                    viewModel.refresh()
                } label: {
                    L10n.retry.text
                        .bold()
                        .font(.callout)
                        .frame(width: 400, height: 75)
                        .background(Color.jellyfinPurple)
                }
                .buttonStyle(.card)
            }
            .offset(y: -50)
        }
    }
}
