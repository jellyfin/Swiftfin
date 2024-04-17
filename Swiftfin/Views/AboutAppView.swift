//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct AboutAppView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @ObservedObject
    var viewModel: SettingsViewModel

    var body: some View {
        List {
            Section {
                VStack(alignment: .center) {

                    Image(uiImage: viewModel.currentAppIcon.iconPreview)
                        .resizable()
                        .frame(width: 150, height: 150)
                        .cornerRadius(150 / 6.4)
                        .shadow(radius: 5)

                    // App name, not to be localized
                    Text("Swiftfin")
                        .fontWeight(.semibold)
                        .font(.title2)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section {

                TextPairView(
                    leading: L10n.version,
                    trailing: "\(UIApplication.appVersion ?? .emptyDash) (\(UIApplication.bundleVersion ?? .emptyDash))"
                )

                ChevronButton(title: L10n.sourceCode)
                    .leadingView {
                        Image(.logoGithub)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.primary)
                    }
                    .onSelect {
                        UIApplication.shared.open(.swiftfinGithub)
                    }

                ChevronButton(title: L10n.bugsAndFeatures)
                    .leadingView {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.primary)
                    }
                    .onSelect {
                        UIApplication.shared.open(.swiftfinGithubIssues)
                    }

                ChevronButton(title: L10n.settings)
                    .leadingView {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.primary)
                    }
                    .onSelect {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
            }
        }
    }
}
