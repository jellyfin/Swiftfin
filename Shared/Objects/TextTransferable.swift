//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreTransferable
import Foundation
import SwiftUI
import UniformTypeIdentifiers

public protocol TextTransferable: Transferable {

    var transferTitle: String { get }
    var transferBody: String { get }
}

public extension TextTransferable {

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { (item: Self) in
            Data(item.transferBody.utf8)
        }
        .suggestedFileName { $0.transferTitle.appending(".txt") }
    }

    #if os(iOS)
    var shareLink: some View {
        ShareLink(
            item: self,
            preview: SharePreview(transferTitle)
        )
    }

    func shareLink(@ViewBuilder label: () -> some View) -> some View {
        ShareLink(
            item: self,
            preview: SharePreview(transferTitle),
            label: label
        )
    }
    #endif
}
