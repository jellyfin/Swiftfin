//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Stinsen
import SwiftUI

struct UserSignInView: View {

    @ObservedObject
    var viewModel: UserSignInViewModel
    @State
    private var username: String = ""
    @State
    private var password: String = ""

    var body: some View {
        ZStack {
            ImageView(ImageAPI.getSplashscreenWithRequestBuilder().url)
                .ignoresSafeArea()

            Color.black
                .opacity(0.9)
                .ignoresSafeArea()

            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Section {
                        TextField(L10n.username, text: $username)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)

                        SecureField(L10n.password, text: $password)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)

                        Button {
                            viewModel.signIn(username: username, password: password)
                        } label: {
                            HStack {
                                L10n.connect.text

                                Spacer()

                                if viewModel.isLoading {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(viewModel.isLoading || username.isEmpty)

                    } header: {
                        L10n.signInToServer(viewModel.server.name).text
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if !viewModel.quickConnectEnabled {
                        L10n.quickConnectNotEnabled.text
                    }
                }
                .frame(maxWidth: .infinity)
                .alert(item: $viewModel.errorMessage) { _ in
                    Alert(
                        title: Text(viewModel.alertTitle),
                        message: Text(viewModel.errorMessage?.message ?? L10n.unknownError),
                        dismissButton: .cancel()
                    )
                }
                .navigationTitle(L10n.signIn)

                if viewModel.quickConnectEnabled {
                    VStack(alignment: .center) {
                        L10n.quickConnect.text
                            .font(.title3)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 20) {
                            L10n.quickConnectStep1.text

                            L10n.quickConnectStep2.text

                            L10n.quickConnectStep3.text
                        }
                        .padding(.vertical)

                        Text(viewModel.quickConnectCode ?? "------")
                            .tracking(10)
                            .font(.title)
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        viewModel.startQuickConnect {}
                    }
                    .onDisappear {
                        viewModel.stopQuickConnectAuthCheck()
                    }
                }
            }
        }
    }
}

// struct UserSignInView_Preivews: PreviewProvider {
//    static var previews: some View {
//        UserSignInView(viewModel: .init(server: .sample))
//    }
// }
