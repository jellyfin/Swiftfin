//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import Get
import JellyfinAPI
import UIKit

extension UserDto {
    func profileImageSource(client: JellyfinClient, maxWidth: CGFloat, maxHeight: CGFloat) -> ImageSource {
        let scaleWidth = UIScreen.main.scale(maxWidth)
        let scaleHeight = UIScreen.main.scale(maxHeight)

        let path = Paths.getUserImage(
            userID: id ?? "",
            imageType: "Primary",
            parameters: .init(maxWidth: scaleWidth, maxHeight: scaleHeight)
        )

        let profileImageURL = client.fullURL(with: path)
        print("profile image url: \(profileImageURL.absoluteString)")

        return ImageSource(url: profileImageURL, blurHash: nil)
    }
}

extension JellyfinClient {

    func fullURL<T>(with request: Request<T>) -> URL {
        let fullPath = configuration.url.appendingPathComponent(request.url)

        var components = URLComponents(string: fullPath.absoluteString)!
        components.queryItems = request.query?.map { URLQueryItem(name: $0.0, value: $0.1) } ?? []

        return components.url ?? fullPath
    }
    
    func fullURL(with path: String) -> URL {
        configuration.url.appendingPathComponent(path)
    }
}
