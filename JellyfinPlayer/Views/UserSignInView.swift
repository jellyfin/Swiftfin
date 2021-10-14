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
                TextField("Username", text: $username)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                
                Button {
                    viewModel.login(username: username, password: password)
                } label: {
                    HStack {
                        Text("Connect")
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isLoading || username.isEmpty)

            } header: {
                Text("Sign In to \(viewModel.server.name)")
            }
        }
        .navigationTitle("Sign In")
    }
}
