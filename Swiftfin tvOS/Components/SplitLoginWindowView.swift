//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct SplitLoginWindowView: View {

    // MARK: - Loading State

    private var isLoading: Bool

    // MARK: - Content Variables

    private var leadingTitle: String
    private var leadingContentView: () -> any View
    private var trailingTitle: String
    private var trailingContentView: () -> any View

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
        .navigationBarBranding(isLoading: true)
    }
}

extension SplitLoginWindowView {

    init(isLoading: Bool = false, leadingTitle: String, trailingTitle: String) {
        self.isLoading = isLoading
        self.leadingTitle = leadingTitle
        self.trailingTitle = trailingTitle
        self.leadingContentView = { EmptyView() }
        self.trailingContentView = { EmptyView() }
    }

    func leadingContentView(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.leadingContentView, with: content)
    }

    func trailingContentView(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trailingContentView, with: content)
    }
}
