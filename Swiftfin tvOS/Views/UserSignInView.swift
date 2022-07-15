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
		ZStack {
			ImageView(viewModel.getSplashscreenUrl())
				.ignoresSafeArea()

			Color.black
				.opacity(0.9)
				.ignoresSafeArea()

			HStack(alignment: .top) {
				Form {
					Section {
						TextField(L10n.username, text: $username)
							.disableAutocorrection(true)
							.autocapitalization(.none)

						SecureField(L10n.password, text: $password)
							.disableAutocorrection(true)
							.autocapitalization(.none)

						Button {
							viewModel.login(username: username, password: password)
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
					}
				}
				.frame(maxWidth: .infinity)
				.alert(item: $viewModel.errorMessage) { _ in
					Alert(title: Text(viewModel.alertTitle),
					      message: Text(viewModel.errorMessage?.message ?? L10n.unknownError),
					      dismissButton: .cancel())
				}
				.navigationTitle(L10n.signIn)

				// MARK: Quick Connect

				if let magic = viewModel.magicCode, !magic.isEmpty {
					VStack(alignment: .leading) {
						L10n.useQuickConnectWithoutPassword.text
							.font(.title3)
							.padding(.vertical)

						L10n.useQuickConnectStep1.text
							.padding(.vertical, 20)

						L10n.useQuickConnectStep2.text
							.padding(.vertical, 20)

						L10n.useQuickConnectStep3.text
							.padding(.vertical, 20)

						Text(magic)
							.tracking(10)
							.font(.title)
							.padding(.all)
							.monospacedDigit()
					}
					.frame(maxWidth: .infinity)
				}
			}
		}
		.onAppear(perform: viewModel.startQuickConnect)
	}
}

struct UserSignInView_Preivews: PreviewProvider {

	static let mode = UserSignInViewModel(server: SwiftfinStore.State.Server.sample)

	static var previews: some View {

		UserSignInView(viewModel: mode)
	}
}
