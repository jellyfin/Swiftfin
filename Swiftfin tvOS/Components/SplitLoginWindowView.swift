//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct SplitLoginWindowView<Leading: View, Trailing: View>: View {

    // MARK: - Loading State

    private let isLoading: Bool

    // MARK: - Content Variables

    private let leadingTitle: String
    private let leadingContentView: () -> Leading
    private let trailingTitle: String
    private let trailingContentView: () -> Trailing

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Section(leadingTitle) {
                    VStack(alignment: .leading) {
                        leadingContentView()
                            .eraseToAnyView()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
            }

            Divider()
                .padding(.vertical, 100)

            VStack(alignment: .leading) {
                Section(trailingTitle) {
                    VStack(alignment: .leading) {
                        trailingContentView()
                            .eraseToAnyView()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
            }
        }
        .navigationBarBranding(isLoading: isLoading)
    }
}

extension SplitLoginWindowView {

    init(
        isLoading: Bool = false,
        leadingTitle: String,
        trailingTitle: String,
        @ViewBuilder leadingContentView: @escaping () -> Leading,
        @ViewBuilder trailingContentView: @escaping () -> Trailing
    ) {
        self.isLoading = isLoading
        self.leadingTitle = leadingTitle
        self.trailingTitle = trailingTitle
        self.leadingContentView = leadingContentView
        self.trailingContentView = trailingContentView
    }
}
