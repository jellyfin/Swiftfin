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

    // MARK: – Inject Logger

    @Injected(\.logService)
    private var logger

    // MARK: – Properties

    private let group: EventLoopGroup
    private var channel: Channel?
    private let discoveredServersPublisher = PassthroughSubject<ServerResponse, Never>()
    private let stateSubject = CurrentValueSubject<State, Never>(.inactive)

    // MARK: – Public API

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

    // MARK: – Initializer

    init() {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        bindChannel()
    }

    deinit {
        // final tear-down
        channel?.close(promise: nil)
        discoveredServersPublisher.send(completion: .finished)
        _ = group.shutdownGracefully { _ in }
    }

    // MARK: – Core

    /// Ensure we have a bound channel; on failure, publish .error
    private func bindChannel() {
        guard channel == nil else { return }

        let bootstrap = DatagramBootstrap(group: group)
            .channelOption(ChannelOptions.autoRead, value: true)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelOption(ChannelOptions.socketOption(.so_broadcast), value: 1)
            .channelInitializer { ch in
                ch.pipeline.addHandler(Handler(parent: self))
            }

        do {
            channel = try bootstrap.bind(host: "0.0.0.0", port: 7359).wait()
            logger.debug("Bound UDP to \(channel!.localAddress!)")
        } catch {
            logger.error("Bind error: \(error.localizedDescription)")
            stateSubject.send(.error(JellyfinAPIError(error.localizedDescription)))
        }
    }

    // MARK: – Reset

    /// Closes and clears the channel so the next broadcast will re-bind
    func reset() {
        channel?.close(promise: nil)
        channel = nil
        stateSubject.send(.inactive)
    }

    // MARK: – Broadcast Discovery Request

    /// Broadcasts a discovery request, emits `.active`, then after 5 s emits `.inactive`
    func broadcast() {
        // lazy re-bind if needed
        bindChannel()
        guard let ch = channel else {
            logger.error("Broadcast called before channel ready")
            stateSubject.send(.error(JellyfinAPIError("Channel not ready")))
            return
        }

        let payload = "Who is JellyfinServer?"
        var buffer = ch.allocator.buffer(capacity: payload.utf8.count)
        buffer.writeString(payload)

        let addrs = Self.allBroadcastAddresses()
        logger.debug("Broadcast targets: \(addrs)")
        let filtered = addrs.filter { $0.hasSuffix(".255") && $0 != "0.0.0.0" }
        let targets = filtered.isEmpty ? ["255.255.255.255"] : filtered

        for bc in targets {
            do {
                let addr = try SocketAddress(ipAddress: bc, port: 7359)
                ch.writeAndFlush(AddressedEnvelope(remoteAddress: addr, data: buffer), promise: nil)
            } catch {
                logger.debug("Invalid address \(bc): \(error.localizedDescription)")
            }
        }

        stateSubject.send(.active)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.logger.debug("Discovery window ended")
            self.stateSubject.send(.inactive)
        }
    }

    // MARK: – Channel Handler

    private final class Handler: ChannelInboundHandler {
        typealias InboundIn = AddressedEnvelope<ByteBuffer>
        private weak var parent: ServerDiscovery?

        init(parent: ServerDiscovery) { self.parent = parent }

        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            guard let parent = parent else { return }
            let env = unwrapInboundIn(data)
            let buf = env.data

            guard let bytes = buf.getBytes(at: buf.readerIndex, length: buf.readableBytes),
                  bytes.first == UInt8(ascii: "{")
            else {
                parent.logger.debug("Skipping non-JSON packet")
                return
            }

            let raw = Data(bytes)
            do {
                let resp = try JSONDecoder().decode(ServerResponse.self, from: raw)
                parent.logger.debug("Decoded server: \(resp.name) @ \(resp.url)")
                DispatchQueue.main.async {
                    parent.discoveredServersPublisher.send(resp)
                }
            } catch {
                parent.logger.error("JSON decode failed: \(error.localizedDescription)")
                if let s = String(data: raw, encoding: .utf8) {
                    parent.logger.debug("Raw payload: \(s)")
                }
            }
        }

        func errorCaught(context: ChannelHandlerContext, error: Error) {
            parent?.logger.debug("Channel error: \(error.localizedDescription)")
            context.close(promise: nil)
        }
    }

    // MARK: – Utilities

    private static func allBroadcastAddresses() -> [String] {
        var results = [String]()
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let first = ifaddrPtr else { return [] }

        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_BROADCAST != 0 else { continue }
            guard let addrPtr = ptr.pointee.ifa_addr,
                  addrPtr.pointee.sa_family == sa_family_t(AF_INET)
            else { continue }

            let ipv4 = addrPtr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            let mask = ptr.pointee.ifa_netmask!
                .withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }

            let net = UInt32(bigEndian: ipv4.sin_addr.s_addr)
            let m = UInt32(bigEndian: mask.sin_addr.s_addr)
            let bc = net | ~m

            var inAddr = in_addr(s_addr: bc.bigEndian)
            if let cstr = inet_ntoa(inAddr) {
                results.append(String(cString: cstr))
            }
        }
        freeifaddrs(ifaddrPtr)
        return results
    }
}
