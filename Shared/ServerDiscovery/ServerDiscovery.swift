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
import JellyfinAPI
import NIO

class ServerDiscovery {

    // MARK: - Inject Logger

    @Injected(\.logService)
    private var logger

    // MARK: - Static Variables

    private let discoveryPort = 7359
    private let ipv6MulticastGroup = "ff02::1:1000"

    // MARK: - Discovery Properties

    private var ipv4Channel: Channel?
    private var ipv6Channel: Channel?

    private let group: EventLoopGroup

    // MARK: - Published Variables

    private let discoveredServersPublisher = PassthroughSubject<ServerResponse, Never>()
    private let stateSubject = CurrentValueSubject<State, Never>(.inactive)

    var discoveredServers: AnyPublisher<ServerResponse, Never> {
        discoveredServersPublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var state: AnyPublisher<State, Never> {
        stateSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Initializer

    /// Initialize the discovery service and set up channels
    init() {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        bindChannel()
    }

    // MARK: - Deinitializer

    /// Clean up resources when the object is deallocated
    deinit {
        ipv4Channel?.close(promise: nil)
        ipv6Channel?.close(promise: nil)
        discoveredServersPublisher.send(completion: .finished)
        _ = group.shutdownGracefully { _ in }
    }

    // MARK: - Reset

    /// Reset the discovery service by closing and nullifying channels
    func reset() {
        ipv4Channel?.close(promise: nil)
        ipv6Channel?.close(promise: nil)
        ipv4Channel = nil
        ipv6Channel = nil
        stateSubject.send(.inactive)
    }

    // MARK: - Discovery Orchestration

    /// Broadcast discovery messages over IPv4 and IPv6
    func broadcast() {
        bindChannel()

        let payload = "Who is JellyfinServer?"
        let ipv4Sent = sendIPv4(payload: payload)
        let ipv6Sent = sendIPv6(payload: payload)

        if ipv4Sent || ipv6Sent {
            stateSubject.send(.active)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.logger.debug("Discovery window ended")
                self.stateSubject.send(.inactive)
            }
        } else {
            stateSubject.send(.error(JellyfinAPIError("No channels ready")))
        }
    }

    // MARK: - Channel Binding

    /// Create and bind channels if they don't exist
    private func bindChannel() {
        if ipv4Channel == nil {
            do {
                ipv4Channel = try bindIPv4()
                logger.debug("Bound IPv4 UDP to \(ipv4Channel!.localAddress!)")
            } catch {
                logger.error("IPv4 bind error: \(error.localizedDescription)")
                stateSubject.send(.error(JellyfinAPIError(error.localizedDescription)))
            }
        }

        if ipv6Channel == nil {
            do {
                ipv6Channel = try bindIPv6()
                logger.debug("Bound IPv6 UDP to \(ipv6Channel!.localAddress!)")
            } catch {
                logger.debug("IPv6 bind error: \(error.localizedDescription)")
                if ipv4Channel == nil {
                    stateSubject.send(.error(JellyfinAPIError(error.localizedDescription)))
                }
            }
        }
    }

    // MARK: - Channel Binding - IPv4

    private func bindIPv4() throws -> Channel {
        let host = Self.getDeviceIPv4Address() ?? "0.0.0.0"

        let bootstrap = DatagramBootstrap(group: group)
            .channelOption(ChannelOptions.autoRead, value: true)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelOption(ChannelOptions.socketOption(.so_broadcast), value: 1)
            .channelInitializer { $0.pipeline.addHandler(Handler(parent: self)) }

        return try bootstrap.bind(host: host, port: discoveryPort).wait()
    }

    // MARK: - Channel Binding - IPv6

    private func bindIPv6() throws -> Channel {
        guard let (address, _) = Self.getDeviceIPv6Address() else {
            throw JellyfinAPIError("No IPv6 interface")
        }

        let bootstrap = DatagramBootstrap(group: group)
            .channelOption(ChannelOptions.autoRead, value: true)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelOption(ChannelOptions.socketOption(.ipv6_v6only), value: 1)
            .channelOption(ChannelOptions.socketOption(.ipv6_multicast_hops), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(Handler(parent: self))
            }

        return try bootstrap.bind(host: address, port: discoveryPort).wait()
    }

    // MARK: - Discovery Send - IPv4

    /// Send discovery message using IPv4 broadcast
    private func sendIPv4(payload: String) -> Bool {
        guard let channel = ipv4Channel else {
            logger.error("IPv4 broadcast called before channel ready")
            return false
        }

        // Send to global broadcast address for widest coverage
        do {
            let address = try SocketAddress(ipAddress: "255.255.255.255", port: discoveryPort)
            var data = channel.allocator.buffer(capacity: payload.utf8.count)
            data.writeString(payload)

            let promise = channel.eventLoop.makePromise(of: Void.self)
            promise.futureResult.whenFailure { error in
                self.logger.error("Global broadcast failed: \(error.localizedDescription)")
                self.logDetailedSocketError(error)
            }

            channel.writeAndFlush(AddressedEnvelope(remoteAddress: address, data: data), promise: promise)
            return true
        } catch {
            logger.error("Failed to send global broadcast: \(error.localizedDescription)")
        }

        return true
    }

    // MARK: - Discovery Send - IPv6

    /// Send discovery message using IPv6 broadcast
    private func sendIPv6(payload: String) -> Bool {
        guard let channel = ipv6Channel else { return false }

        // Use global scope multicast instead of link-local for better compatibility
        let alternateMulticast = "ff0e::1:1000"

        do {
            let address = try SocketAddress(ipAddress: alternateMulticast, port: discoveryPort)
            var data = channel.allocator.buffer(capacity: payload.utf8.count)
            data.writeString(payload)

            let promise = channel.eventLoop.makePromise(of: Void.self)
            promise.futureResult.whenComplete { result in
                switch result {
                case .success:
                    self.logger.debug("Successfully sent IPv6 multicast to \(alternateMulticast)")
                case let .failure(error):
                    self.logger.debug("IPv6 global multicast failed: \(error.localizedDescription)")
                }
            }

            channel.writeAndFlush(AddressedEnvelope(remoteAddress: address, data: data), promise: promise)
        } catch {
            logger.debug("IPv6 multicast setup error: \(error.localizedDescription)")
        }

        return true
    }

    // MARK: - Helper Methods

    /// Log detailed information about socket errors for diagnosis
    private func logDetailedSocketError(_ error: Error) {
        let socketError = error as NSError

        logger.error("Socket error details:")
        logger.error("→ Domain: \(socketError.domain)")
        logger.error("→ Code: \(socketError.code)")

        if socketError.domain == NSPOSIXErrorDomain {
            let domainError = socketError.code

            logger.error("→ POSIX error: \(domainError) (\(String(cString: strerror(Int32(domainError)))))")
        }

        if let errorKey = socketError.userInfo[NSUnderlyingErrorKey] as? NSError {
            logger.error("→ Underlying Error: \(errorKey.localizedDescription) (code: \(errorKey.code))")
        }
    }

    // MARK: - Channel Handler

    /// Handler for processing incoming UDP packets
    private final class Handler: ChannelInboundHandler {
        typealias InboundIn = AddressedEnvelope<ByteBuffer>
        private weak var parent: ServerDiscovery?

        init(parent: ServerDiscovery) {
            self.parent = parent
        }

        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            guard let parent = parent else { return }

            let envelope = unwrapInboundIn(data)
            let buffer = envelope.data

            guard let bytes = buffer.getBytes(at: buffer.readerIndex, length: buffer.readableBytes),
                  bytes.first == UInt8(ascii: "{")
            else {
                parent.logger.debug("Skipping non-JSON packet")
                return
            }

            let raw = Data(bytes)
            do {
                let response = try JSONDecoder().decode(ServerResponse.self, from: raw)
                parent.logger.debug("Decoded server: \(response.name) @ \(response.url) from \(envelope.remoteAddress)")
                DispatchQueue.main.async {
                    parent.discoveredServersPublisher.send(response)
                }
            } catch {
                parent.logger.error("JSON decode failed: \(error.localizedDescription)")
                if let string = String(data: raw, encoding: .utf8) {
                    parent.logger.debug("Raw payload: \(string)")
                }
            }
        }

        func errorCaught(context: ChannelHandlerContext, error: Error) {
            parent?.logger.debug("Channel error: \(error.localizedDescription)")
            context.close(promise: nil)
        }
    }

    // MARK: - Broadcast All Addresses over UDP

    /// Calculate all IPv4 broadcast addresses for network interfaces
    private static func allBroadcastAddresses() -> [String] {
        var results = [String]()
        var ifaddrPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPointer) == 0, let first = ifaddrPointer else { return [] }

        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let flags = Int32(pointer.pointee.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_BROADCAST != 0 else { continue }

            guard let addrPointer = pointer.pointee.ifa_addr,
                  addrPointer.pointee.sa_family == sa_family_t(AF_INET) else { continue }

            let ipv4 = addrPointer.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            let mask = pointer.pointee.ifa_netmask!
                .withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }

            let net = UInt32(bigEndian: ipv4.sin_addr.s_addr)
            let maskValue = UInt32(bigEndian: mask.sin_addr.s_addr)
            let broadcast = net | ~maskValue

            let inAddr = in_addr(s_addr: broadcast.bigEndian)
            if let cstr = inet_ntoa(inAddr) {
                results.append(String(cString: cstr))
            }
        }

        freeifaddrs(ifaddrPointer)
        return results
    }

    // MARK: - Get Device IPv4

    /// Returns first non-loopback IPv4 address (e.g. "192.168.1.42")
    /// https://github.com/apple/swift-nio/issues/1494
    private static func getDeviceIPv4Address() -> String? {
        var pointer: UnsafeMutablePointer<ifaddrs>?

        defer { pointer.flatMap(freeifaddrs) }

        guard getifaddrs(&pointer) == 0, let first = pointer else { return nil }

        for current in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let flags = Int32(current.pointee.ifa_flags)

            guard flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0 else { continue }
            guard current.pointee.ifa_addr.pointee.sa_family == sa_family_t(AF_INET) else { continue }

            var address = current.pointee.ifa_addr.withMemoryRebound(
                to: sockaddr_in.self, capacity: 1
            ) { $0.pointee.sin_addr }

            var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            inet_ntop(AF_INET, &address, &buffer, socklen_t(INET_ADDRSTRLEN))

            return String(cString: buffer)
        }
        return nil
    }

    // MARK: - Get Device IPv6

    /// Returns first non-loopback scoped IPv6 address and its interface index
    /// https://github.com/apple/swift-nio/issues/1494
    private static func getDeviceIPv6Address() -> (String, UInt32)? {
        var pointer: UnsafeMutablePointer<ifaddrs>?

        defer { pointer.flatMap(freeifaddrs) }

        guard getifaddrs(&pointer) == 0, let first = pointer else { return nil }

        for current in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let flags = Int32(current.pointee.ifa_flags)

            guard flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0 else { continue }
            guard current.pointee.ifa_addr.pointee.sa_family == sa_family_t(AF_INET6) else { continue }

            var socketAddressIPv6 = current.pointee.ifa_addr.withMemoryRebound(
                to: sockaddr_in6.self, capacity: 1
            ) { $0.pointee }

            var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            inet_ntop(AF_INET6, &socketAddressIPv6.sin6_addr, &buffer, socklen_t(INET6_ADDRSTRLEN))

            let name = String(cString: current.pointee.ifa_name)
            let index = if_nametoindex(name)

            return ("\(String(cString: buffer))%\(name)", UInt32(index))
        }
        return nil
    }
}
