//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct AppIconSelectorView: View {

    @ObservedObject
    var viewModel: SettingsViewModel

    var body: some View {
        Form {

            Section {
                ForEach(PrimaryAppIcon.allCases) { icon in
                    AppIconRow(viewModel: viewModel, icon: icon)
                }
            }

            Section(L10n.dark) {
                ForEach(DarkAppIcon.allCases) { icon in
                    AppIconRow(viewModel: viewModel, icon: icon)
                }
            }

            Section(L10n.light) {
                ForEach(LightAppIcon.allCases) { icon in
                    AppIconRow(viewModel: viewModel, icon: icon)
                }
            }

            Section(L10n.invertedDark) {
                ForEach(InvertedDarkAppIcon.allCases) { icon in
                    AppIconRow(viewModel: viewModel, icon: icon)
                }
            }

            Section(L10n.invertedLight) {
                ForEach(InvertedLightAppIcon.allCases) { icon in
                    AppIconRow(viewModel: viewModel, icon: icon)
                }
            }
        }
        .navigationTitle(L10n.appIcon)
    }
}

extension AppIconSelectorView {

    struct AppIconRow: View {

        @Default(.accentColor)
        private var accentColor

        @ObservedObject
        var viewModel: SettingsViewModel

        let icon: any AppIcon

        var body: some View {
            Button {
                viewModel.select(icon: icon)
            } label: {
                HStack {

                    Image(icon.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .cornerRadius(12)
                        .shadow(radius: 2)

                    Text(icon.displayTitle)
                        .foregroundColor(.primary)

                    Spacer()

                    if icon.iconName == viewModel.currentAppIcon.iconName {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .backport
                            .fontWeight(.bold)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(accentColor.overlayColor, accentColor)
                    }
                }
            }
        }
    }
}
