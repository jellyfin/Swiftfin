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

    var subtitle: String? {
        firstRole
    }

    var systemImage: String {
        "person.fill"
    }

    func portraitImageSources(maxWidth: CGFloat? = nil, quality: Int? = nil) -> [ImageSource] {

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

        let url = client.url(with: imageRequest)
        let blurHash: String? = imageBlurHashes?.primary?[primaryImageTag]

        return [ImageSource(
            url: url,
            blurHash: blurHash
        )]
    }

    func transform(image: Image) -> some View {
        image
    }
}

// struct BaseItemPersonListRow: View {
//
//    @Environment(\.isEditing)
//    private var isEditing
//    @Environment(\.isSelected)
//    private var isSelected
//
//    let person: BaseItemPerson
//    var isSeparatorVisible: Bool = true
//    var action: () -> Void = {}
//
//    var body: some View {
//        ListRow {
//            PosterImage(
//                item: person,
//                type: .portrait
//            )
//            .posterStyle(.portrait)
//            .frame(width: 60)
//            .posterShadow()
//        } content: {
//            HStack {
//                VStack(alignment: .leading, spacing: 5) {
//                    Text(person.displayTitle)
//                        .font(.callout)
//                        .fontWeight(.semibold)
//                        .lineLimit(2)
//                        .multilineTextAlignment(.leading)
//
//                    if let subtitle = person.subtitle {
//                        Text(subtitle)
//                            .font(.caption)
//                            .foregroundStyle(.secondary)
//                            .lineLimit(1)
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .foregroundStyle(
//                    isEditing ? (isSelected ? .primary : .secondary) : .primary
//                )
//
//                if isEditing {
//                    Spacer()
//
//                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
//                        .resizable()
//                        .aspectRatio(1, contentMode: .fit)
//                        .frame(width: 24, height: 24)
//                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
//                }
//            }
//        } action: {
//            action()
//        }
//        .withViewContext(.isListRowSeparatorVisible)
////        .isSeparatorVisible(isSeparatorVisible)
//    }
// }
