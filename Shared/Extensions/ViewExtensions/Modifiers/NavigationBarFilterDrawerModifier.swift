//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NavigationBarFilterDrawerModifier: ViewModifier {

    @ObservedObject
    var viewModel: FilterViewModel

    let types: [ItemFilterType]

    @ViewBuilder
    private var drawer: some View {
        NavigationBarFilterDrawer(
            viewModel: viewModel,
            types: types
        )
    }

    func body(content: Content) -> some View {
        if types.isEmpty {
            content
        } else {
            if #available(iOS 26, *) {
                content
                    #if os(tvOS)
                        .mask(extendedBy: .init(vertical: 100, horizontal: 100)) {
                            VStack(spacing: 0) {
                                Color.clear
                                    .frame(height: 80)

                                LinearGradient(
                                    colors: [.clear, .white],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 20)

                                Color.white
                            }
                        }
                    #endif
                        .safeAreaBar(edge: .top, spacing: 0) {
                            drawer
                                .isolatedHosting()
                    }
                    .preference(key: IsSafeAreaBarApplied.self, value: true)
            } else {
                #if os(iOS)
                NavigationBarDrawerView {
                    drawer
                        .ignoresSafeArea()
                } content: {
                    content
                }
                .ignoresSafeArea()
                #endif
            }
        }
    }
}
