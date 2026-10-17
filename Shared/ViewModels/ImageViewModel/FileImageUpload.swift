//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import UIKit

enum FileImageUpload {

    struct Payload: Sendable {
        let body: Data
        let contentType: String
    }

    enum PreparationError: Error {
        case accessDenied
        case invalidImage
    }

    private static let queue = DispatchQueue(label: "Swiftfin.FileImageUpload", qos: .userInitiated)

    static func prepare(_ file: URL) async throws -> Payload {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    guard file.startAccessingSecurityScopedResource() else {
                        throw PreparationError.accessDenied
                    }

                    defer { file.stopAccessingSecurityScopedResource() }

                    guard let image = try UIImage(data: Data(contentsOf: file)) else {
                        throw PreparationError.invalidImage
                    }

                    let (data, contentType) = try image.data()
                    let payload = Payload(body: data.base64EncodedData(), contentType: contentType)

                    continuation.resume(returning: payload)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
