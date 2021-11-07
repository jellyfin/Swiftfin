//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI
import Stinsen

struct UserSignInView: View {

    @ObservedObject var viewModel: UserSignInViewModel
    @State private var username: String = ""
    @State private var password: String = ""

    var body: some View {
        Form {

            Section {
                TextField(L10n.username, text: $username)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)

                SecureField(L10n.password, text: $password)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)

                if viewModel.isLoading {
                    Button(role: .destructive) {
                        viewModel.cancelSignIn()
                    } label: {
                        Text("Cancel")
                    }
                } else {
                    Button {
                        viewModel.login(username: username, password: password)
                    } label: {
                        Text("Sign In")
                    }
                    .disabled(username.isEmpty)
                }
            } header: {
                Text("Sign In to \(viewModel.server.name)")
            }
        }
        .alert(item: $viewModel.errorMessage) { _ in
            Alert(title: Text(viewModel.alertTitle),
                  message: Text(viewModel.errorMessage?.displayMessage ?? "Unknown Error"),
                  dismissButton: .cancel())
        }
        .navigationTitle("Sign In")
        .navigationBarBackButtonHidden(viewModel.isLoading)
    }
}
