//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct AboutAppView: View {

    var body: some View {
        Form(image: .jellyfinBlobBlue) {

            #if os(iOS)
            Section {
                VStack(alignment: .center, spacing: 10) {

                    Image(.jellyfinBlobBlue)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(height: 150)

                    Text(verbatim: "Swiftfin")
                        .fontWeight(.semibold)
                        .font(.title2)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
            #endif

            Section {
                LabeledContent(
                    L10n.version,
                    value: "\(UIApplication.appVersion ?? .emptyDash) (\(UIApplication.bundleVersion ?? .emptyDash))"
                )
            }

            Section {

                // tvOS cannot open generic web links
                #if !os(tvOS)
                ChevronButton(
                    L10n.sourceCode,
                    image: .logoGithub,
                    external: true
                ) {
                    UIApplication.shared.open(.swiftfinGithub)
                }

                ChevronButton(
                    L10n.license,
                    content: L10n.mlp2,
                    systemName: "text.document",
                    external: true
                ) {
                    UIApplication.shared.open(.swiftfinGithubLicense)
                }

                ChevronButton(
                    L10n.bugsAndFeatures,
                    systemName: "plus.circle.fill",
                    external: true
                ) {
                    UIApplication.shared.open(.swiftfinGithubIssues)
                }
                .symbolRenderingMode(.monochrome)
                #endif

                ChevronButton(
                    L10n.settings,
                    systemName: "gearshape.fill",
                    external: true
                ) {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            }
        }
        .navigationTitle(L10n.about)
    }
}
