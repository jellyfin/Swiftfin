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
    
    @Default(.appAppearance) var appAppearance
    
    var body: some View {
        Form {
            Section {
                Picker(NSLocalizedString("Appearance", comment: ""), selection: $appAppearance) {
                    ForEach(self.viewModel.appearances, id: \.self) { appearance in
                        Text(appearance.localizedName).tag(appearance.rawValue)
                    }
                }.onChange(of: appAppearance, perform: { _ in
                    UIApplication.shared.windows.first?.overrideUserInterfaceStyle = appAppearance.style
                })
            } header: {
                Text("Accessibility")
            }

        }
        .navigationBarTitle("Settings", displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    basicAppSettingsRouter.dismissCoordinator()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
    }
}
