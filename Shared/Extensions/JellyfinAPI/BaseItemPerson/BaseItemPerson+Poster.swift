//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import SwiftUI

extension BaseItemPerson: Poster {

    var preferredPosterDisplayType: PosterDisplayType {
        .portrait
    }

    var posterLabel: some View {
        TitleSubtitleContentView(
            title: displayTitle,
            subtitle: role ?? "!!!"
        )
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
        guard let primaryImageTag else { return [] }

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
        WithRouter { router in
            PosterButton(
                item: self,
                type: .portrait
            ) { namespace in
                libraryDidSelectElement(router: router, in: namespace)
            }
        }
    }

    func makeListBody(libraryStyle: LibraryStyle) -> some View {
        WithNamespace { namespace in
            WithRouter { router in
                ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
                    libraryDidSelectElement(router: router, in: namespace)
                } leading: {
                    PosterImage(
                        item: self,
                        type: .portrait,
                        contentMode: .fill
                    )
                    .posterShadow()
                    .frame(width: 60)
                } content: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(displayTitle)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if let role {
                            Text(role)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .backport
                .matchedTransitionSource(id: "item", in: namespace)
            }
        }
    }
}
