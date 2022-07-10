//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct UserLoginCellView: View {

	@State
	private var expanded = false

	@State
	private var enteredPassword: String = ""

	var user: UserDto
	var baseURL: String?
	var loginTapped: (String, String) -> Void
	var cancelTapped: () -> Void

	var body: some View {
		DisclosureGroup {
			VStack(alignment: .leading, spacing: 16) {
				SecureField(L10n.password, text: $enteredPassword)
				Button {
					loginTapped(user.name ?? "", enteredPassword)
				} label: {
					L10n.signIn.text
				}
			}
			.padding(.leading, -16)
		} label: {
			HStack(spacing: 4.0) {
				AsyncImage(url: getProfileImageUrl(),
				           content: { image in
				           	image.resizable()
				           		.aspectRatio(contentMode: .fit)
				           		.frame(maxWidth: 50, maxHeight: 50)
				           		.clipShape(Circle())
				           },
				           placeholder: {
				           	Image(systemName: "person.circle")
				           		.resizable()
				           		.font(.system(size: 40))
				           		.scaledToFit()
				           		.frame(maxWidth: 50, maxHeight: 50)
				           })
				           .padding(.vertical, 4.0)

				Text(user.name ?? "")
					.padding(.leading, 4.0)
				Spacer()
			}
		}
	}

	func getProfileImageUrl() -> URL? {
		if let userId = user.id, let imageTag = user.primaryImageTag, let server = baseURL {
			let url = URL(string: "\(server)/Users/\(userId)/Images/Primary?width=200&tag=\(imageTag)&quality=90")
			LogManager.log.debug(url?.absoluteString ?? "")
			return url
		}
		return nil
	}
}
