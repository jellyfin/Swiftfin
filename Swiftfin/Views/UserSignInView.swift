//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

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
		List {
			#if !os(tvOS)
				// DisclosureGroup not available on tvOS
				if !viewModel.users.isEmpty {
					Section(header: L10n.knownUsers.text) {
						ForEach(viewModel.users, id: \.id) { user in
							UserLoginCellView(user: user, baseURL: viewModel.server.currentURI, loginTapped: viewModel.login,
							                  cancelTapped: viewModel.cancelSignIn)
								.disabled(viewModel.isLoading)
						}
					}
				}
			#endif

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
						L10n.cancel.text
					}
				} else {
					Button {
						viewModel.login(username: username, password: password)
					} label: {
						L10n.signIn.text
					}
					.disabled(username.isEmpty)
				}
			} header: {
				L10n.signInToServer(viewModel.server.name).text
			}
		}
		.alert(item: $viewModel.errorMessage) { _ in
			Alert(title: Text(viewModel.alertTitle),
			      message: Text(viewModel.errorMessage?.message ?? L10n.unknownError),
			      dismissButton: .cancel())
		}
		.navigationTitle(L10n.signIn)
		.navigationBarBackButtonHidden(viewModel.isLoading)
		.onAppear(perform: viewModel.loadUsers)
	}
}
