//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import Network
import SwiftUI

extension Container {
    var networkMonitor: Factory<NetworkMonitor> { self { NetworkMonitor() }.shared }
}

class NetworkMonitor: ObservableObject {

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published
    private(set) var isConnected: Bool = true

    @Published
    private(set) var connectionType: NWInterface.InterfaceType?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    func checkConnection() -> Bool {
        isConnected
    }
}
