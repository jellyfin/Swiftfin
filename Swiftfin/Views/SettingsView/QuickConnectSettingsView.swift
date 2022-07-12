//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct QuickConnectSettingsView: View {

	@ObservedObject
	var viewModel: QuickConnectSettingsViewModel

	var body: some View {
		Form {
			Section(header: L10n.quickConnect.text) {
				TextField(L10n.quickConnectCode, text: $viewModel.quickConnectCode)
					.keyboardType(.numberPad)
					.disabled(viewModel.isLoading)

				Button {
					viewModel.sendQuickConnect()
				} label: {
					L10n.authorize.text
						.font(.callout)
						.disabled((viewModel.quickConnectCode.count != 6) || viewModel.isLoading)
				}
			}
			.alert(isPresented: $viewModel.showSuccessMessage) {
				Alert(title: L10n.quickConnect.text,
				      message: L10n.quickConnectSuccessMessage.text,
				      dismissButton: .default(L10n.ok.text))
			}
		}
		.alert(item: $viewModel.errorMessage) { _ in
			Alert(title: Text(viewModel.alertTitle),
			      message: Text(viewModel.errorMessage?.message ?? L10n.unknownError),
			      dismissButton: .cancel())
		}
	}
}
