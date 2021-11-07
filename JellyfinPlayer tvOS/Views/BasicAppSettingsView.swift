//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Defaults
import Stinsen
import SwiftUI

struct BasicAppSettingsView: View {
    
    @EnvironmentObject var basicAppSettingsRouter: BasicAppSettingsCoordinator.Router
    @ObservedObject var viewModel: BasicAppSettingsViewModel
    @State var resetTapped: Bool = false
    
    @Default(.appAppearance) var appAppearance
    
    var body: some View {
        Form {
            Section {
                Picker(L10n.appearance, selection: $appAppearance) {
                    ForEach(self.viewModel.appearances, id: \.self) { appearance in
                        Text(appearance.localizedName).tag(appearance.rawValue)
                    }
                }.onChange(of: appAppearance, perform: { _ in
                    UIApplication.shared.windows.first?.overrideUserInterfaceStyle = appAppearance.style
                })
            } header: {
                L10n.accessibility.text
            }
            
            Button {
                resetTapped = true
            } label: {
                L10n.reset.text
            }
        }
        .alert(L10n.reset, isPresented: $resetTapped, actions: {
            Button(role: .destructive) {
                viewModel.reset()
                basicAppSettingsRouter.dismissCoordinator()
            } label: {
                L10n.reset.text
            }
        })
        .navigationTitle("Settings")
    }
}
