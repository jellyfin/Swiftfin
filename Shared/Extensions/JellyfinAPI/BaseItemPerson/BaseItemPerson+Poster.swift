//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import SwiftUI

extension BaseItemPerson: Poster {

    var preferredPosterDisplayType: PosterDisplayType {
        .portrait
    }

    var unwrappedIDHashOrZero: Int {
        id?.hashValue ?? 0
    }

    var subtitle: String? {
        firstRole
    }

    var systemImage: String {
        "person.fill"
    }

    func portraitImageSources(
        maxWidth: CGFloat?,
        quality: Int?,
        environment: Empty
    ) -> [ImageSource] {
        guard let client = Container.shared.currentUserSession()?.client else { return [] }

        // TODO: figure out what to do about screen scaling with .main being deprecated
        //       - maxWidth assume already scaled?
        let scaleWidth: Int? = maxWidth == nil ? nil : UIScreen.main.scale(maxWidth!)

        let imageRequestParameters = Paths.GetItemImageParameters(
            maxWidth: scaleWidth ?? Int(maxWidth),
            quality: quality,
            tag: primaryImageTag
        )

        let imageRequest = Paths.getItemImage(
            itemID: id ?? "",
            imageType: ImageType.primary.rawValue,
            parameters: imageRequestParameters
        )

        let url = client.fullURL(with: imageRequest)
        let blurHash: String? = imageBlurHashes?.primary?[primaryImageTag]

        return [ImageSource(
            url: url,
            blurHash: blurHash
        )]
    }
}

extension BaseItemPerson: LibraryElement {

    @MainActor
    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID) {
        BaseItemDto(person: self)
            .libraryDidSelectElement(router: router, in: namespace)
    }

    func makeGridBody(libraryStyle: LibraryStyle) -> some View {
        BaseItemDto(person: self)
            .makeGridBody(libraryStyle: libraryStyle)
    }

    func makeListBody(libraryStyle: LibraryStyle) -> some View {
        BaseItemDto(person: self)
            .makeListBody(libraryStyle: libraryStyle)
    }
}
