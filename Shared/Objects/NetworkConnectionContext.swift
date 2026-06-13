//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import Network

#if os(iOS)
import NetworkExtension
#endif

struct NetworkConnectionContext: Equatable {

    let isSatisfied: Bool
    let interface: ServerConnectionInterface
    let wifiSSID: String?
    let isExpensive: Bool
    let isConstrained: Bool

    init(
        isSatisfied: Bool,
        interface: ServerConnectionInterface,
        wifiSSID: String?,
        isExpensive: Bool,
        isConstrained: Bool
    ) {
        self.isSatisfied = isSatisfied
        self.interface = interface
        self.wifiSSID = wifiSSID?.nilIfBlank
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
    }

    init(path: Network.NWPath) {
        self.init(
            isSatisfied: path.status == .satisfied,
            interface: Self.interface(for: path),
            wifiSSID: nil,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained
        )
    }

    static func current(path: Network.NWPath) async -> NetworkConnectionContext {
        let interface = Self.interface(for: path)
        let wifiSSID = path.status == .satisfied && interface == .wifi ? await currentWifiSSID() : nil

        return .init(
            isSatisfied: path.status == .satisfied,
            interface: interface,
            wifiSSID: wifiSSID,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained
        )
    }

    static func current() async -> NetworkConnectionContext {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "Swiftfin.NetworkConnectionContext")
        let resumeState = ContinuationResumeState()

        return await withCheckedContinuation { continuation in
            monitor.pathUpdateHandler = { path in
                guard resumeState.resume() else { return }
                monitor.cancel()

                Task {
                    let context = await Self.current(path: path)
                    continuation.resume(returning: context)
                }
            }

            monitor.start(queue: queue)
        }
    }

    static var unavailable: NetworkConnectionContext {
        .init(
            isSatisfied: false,
            interface: .any,
            wifiSSID: nil,
            isExpensive: false,
            isConstrained: false
        )
    }

    private static func interface(for path: Network.NWPath) -> ServerConnectionInterface {
        if path.usesInterfaceType(.wifi) {
            .wifi
        } else if path.usesInterfaceType(.cellular) {
            .cellular
        } else {
            .any
        }
    }

    static func currentWifiSSID() async -> String? {
        #if os(iOS)
        if #available(iOS 14, *) {
            return await (NEHotspotNetwork.fetchCurrent())?
                .ssid
                .nilIfBlank
        }
        #endif

        return nil
    }

    private final class ContinuationResumeState {

        private let lock = NSLock()
        private var didResume = false

        func resume() -> Bool {
            lock.lock()
            defer { lock.unlock() }

            guard !didResume else { return false }
            didResume = true
            return true
        }
    }
}
