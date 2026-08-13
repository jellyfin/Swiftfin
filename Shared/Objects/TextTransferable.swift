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
        FileRepresentation(exportedContentType: .plainText) { (item: Self) in
            let url = URL.temporaryDirectory.appending(path: item.transferTitle.appending(".txt"))
            try item.transferBody.write(to: url, atomically: true, encoding: .utf8)

            return SentTransferredFile(url)
        }
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
