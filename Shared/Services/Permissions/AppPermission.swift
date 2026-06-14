//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import Foundation

struct AppPermission: CaseIterable, Displayable, Identifiable, Hashable {

    let id: String
    let displayTitle: String
    let privacyDescription: String

    private let canRequestProvider: () -> Bool
    private let requestAction: (String?) async throws -> PermissionStatus
    private let statusProvider: () -> PermissionStatus

    var status: PermissionStatus {
        statusProvider()
    }

    var canRequest: Bool {
        canRequestProvider()
    }

    static let allCases: [AppPermission] = [
        .deviceAuthentication,
        .location,
    ]

    init(
        id: String,
        displayTitle: String,
        privacyDescriptionKey: String,
        canRequest: @escaping () -> Bool,
        request: @escaping (String?) async throws -> PermissionStatus,
        status: @escaping () -> PermissionStatus
    ) {
        self.id = id
        self.displayTitle = displayTitle
        self.privacyDescription = Bundle.main.object(forInfoDictionaryKey: privacyDescriptionKey) as? String ?? ""
        self.canRequestProvider = canRequest
        self.requestAction = request
        self.statusProvider = status
    }

    func request(reason: String?) async throws -> PermissionStatus {
        try await requestAction(reason)
    }

    static func == (lhs: AppPermission, rhs: AppPermission) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
#endif
