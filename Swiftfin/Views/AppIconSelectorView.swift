//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
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

            Section("Dark") {
                ForEach(DarkAppIcon.allCases) { icon in
                    AppIconRow(viewModel: viewModel, icon: icon)
                }
            }

            Section("Light") {
                ForEach(LightAppIcon.allCases) { icon in
                    AppIconRow(viewModel: viewModel, icon: icon)
                }
            }

            Section("Inverted Dark") {
                ForEach(InvertedDarkAppIcon.allCases) { icon in
                    AppIconRow(viewModel: viewModel, icon: icon)
                }
            }

            Section("Inverted Light") {
                ForEach(InvertedLightAppIcon.allCases) { icon in
                    AppIconRow(viewModel: viewModel, icon: icon)
                }
            }
        }
        .navigationTitle("App Icon")
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

                    Image(uiImage: icon.iconPreview)
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
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .foregroundColor(accentColor)
                    } else {
                        Image(systemName: "circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
