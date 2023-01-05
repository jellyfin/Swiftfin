//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct AppAppearanceSelector: View {
    
    @Default(.appAppearance)
    private var appAppearance
    
    @ViewBuilder
    private var moonImage: some View {
        Image(systemName: "moon.fill")
            .resizable()
    }
    
    @ViewBuilder
    private var sunImage: some View {
        Image(systemName: "sun.max.fill")
            .resizable()
    }
    
    @ViewBuilder
    private var descriptionImage: some View {
        switch appAppearance {
        case .dark:
            moonImage
        case .light:
            sunImage
        case .system:
            if UIApplication.shared.keyWindow?.traitCollection.userInterfaceStyle == .dark {
                moonImage
            } else {
                sunImage
            }
        }
    }
    
    var body: some View {
        NavigationView {
            EnumPickerView(selection: $appAppearance)
                .descriptionView {
                    descriptionImage
                        .frame(width: 300, height: 300)
                        .navigationTitle(L10n.appearance)
                }
                .animation(.linear(duration: 0.1), value: appAppearance)
        }
    }
}
