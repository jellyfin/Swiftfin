//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI

struct SplashView: View {
    @StateObject var viewModel = SplashViewModel()
    @State var showingAlert: Bool = false
    
    var body: some View {
        Group {
            if viewModel.isLoggedIn {
                NavigationView() {
                    MainTabView()
                }
                .padding(.leading, -60)
                .padding(.trailing, -60)
            } else {
                NavigationView {
                    ConnectToServerView(isLoggedIn: $viewModel.isLoggedIn)
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Important message"), message: Text("\(ServerEnvironment.current.errorMessage)"), dismissButton: .default(Text("Got it!")))
        }
        .onChange(of: ServerEnvironment.current.hasErrorMessage) { hEM in
            self.showingAlert = hEM
        }
    }
}
