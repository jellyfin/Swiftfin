//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct AboutAppView: View {
    
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

                HStack {
                    L10n.version.text
                    Spacer()
                    Text("\(UIApplication.appVersion ?? .emptyDash) (\(UIApplication.bundleVersion ?? .emptyDash))")
                        .foregroundColor(.secondary)
                }
                
                ChevronButton(title: L10n.sourceCode)
                    .leadingView {
                        Image("logo.github")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.primary)
                    }
                    .onSelect {
                        UIApplication.shared.open(URL(string: "https://www.hackingwithswift.com")!)
                    }
                
                ChevronButton(title: "Bugs and Features")
                    .leadingView {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.primary)
                    }
                    .onSelect {
                        UIApplication.shared.open(URL(string: "https://github.com/jellyfin/Swiftfin/issues")!)
                    }
            }
        }
    }
}
