//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Logging

// MARK: - WebSocket Message Models

private struct ServerSocketMessage: Decodable {

    let messageType: String

    enum CodingKeys: String, CodingKey {
        case messageType = "MessageType"
    }
}

private struct GeneralCommandMessage: Decodable {

    let messageType: String
    let data: CommandData

    struct CommandData: Decodable {

        let name: String
        let arguments: [String: String]?

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case arguments = "Arguments"
        }
    }

    enum CodingKeys: String, CodingKey {
        case messageType = "MessageType"
        case data = "Data"
    }
}

// MARK: - ServerWebSocketClient

/// Manages a persistent WebSocket connection to the Jellyfin server and
/// dispatches server-pushed `GeneralCommand/DisplayMessage` messages to
/// `ServerMessageProxy` for display.
///
/// The client:
/// - Connects using the stored API token and device ID.
/// - Reports `DisplayMessage` + `SupportsMediaControl` capabilities to the
///   server after the first `ForceKeepAlive` acknowledgement, so the
///   dashboard shows the send-message button.
/// - Automatically reconnects with a 5-second backoff on receive errors.
@MainActor
final class ServerWebSocketClient {

    private let logger = Logger.swiftfin()
    private let jellyfinClient: JellyfinClient
    private let serverMessageProxy: ServerMessageProxy

    private var webSocketTask: URLSessionWebSocketTask?
    private var webSocketSession: URLSession?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var isStopped = false
    private var capabilitiesReported = false

    init(jellyfinClient: JellyfinClient, serverMessageProxy: ServerMessageProxy) {
        self.jellyfinClient = jellyfinClient
        self.serverMessageProxy = serverMessageProxy
    }

    // MARK: - Public Interface

    func connect() {
        isStopped = false
        openConnection()
    }

    func disconnect() {
        isStopped = true
        reconnectTask?.cancel()
        receiveTask?.cancel()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        webSocketSession?.invalidateAndCancel()
        webSocketSession = nil
    }

    // MARK: - Connection

    private func openConnection() {
        guard !isStopped else { return }
        guard let wsURL = buildWebSocketURL() else {
            logger.error("ServerWebSocketClient: failed to build WebSocket URL")
            return
        }

        // URLSessionWebSocketTask silently drops headers set on the URLRequest,
        // but httpAdditionalHeaders are forwarded in the HTTP upgrade handshake.
        // This lets the server match the WebSocket to the existing REST session.
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": buildAuthorizationHeader()]
        let session = URLSession(configuration: config)
        webSocketSession = session

        let task = session.webSocketTask(with: wsURL)
        webSocketTask = task
        task.resume()

        capabilitiesReported = false

        receiveTask = Task { [weak self] in
            await self?.receiveMessages()
        }

        logger.info("ServerWebSocketClient: connected", metadata: ["url": .stringConvertible(wsURL)])
    }

    private func buildWebSocketURL() -> URL? {
        let config = jellyfinClient.configuration
        let serverURLString = config.url.absoluteString.trimmingCharacters(in: ["/"])
        let wsBase = serverURLString
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")

        guard var components = URLComponents(string: wsBase + "/socket") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "api_key", value: config.accessToken),
            URLQueryItem(name: "deviceId", value: config.deviceID),
        ]
        return components.url
    }

    private func buildAuthorizationHeader() -> String {
        let config = jellyfinClient.configuration
        var fields: [(String, String)] = [
            ("Client", config.client),
            ("Device", config.deviceName),
            ("DeviceId", config.deviceID),
            ("Version", config.version),
        ]
        if let token = config.accessToken {
            fields.append(("Token", token))
        }
        let joined = fields.map { "\($0.0)=\($0.1)" }.joined(separator: ", ")
        return "MediaBrowser \(joined)"
    }

    // MARK: - Capabilities

    /// Reports that this session supports `DisplayMessage` general commands.
    ///
    /// Called after the first `ForceKeepAlive` rather than immediately on
    /// connect. At that point the server has already added a `WebSocketController`
    /// to the session, so `SupportsMediaControl` evaluates to `true` when the
    /// dashboard refreshes — causing the send-message button to appear.
    private func reportCapabilities() async {
        let capabilities = ClientCapabilitiesDto(
            supportedCommands: [.displayMessage],
            isSupportsMediaControl: true
        )
        do {
            try await jellyfinClient.send(Paths.postFullCapabilities(capabilities))
            logger.info("ServerWebSocketClient: capabilities reported")
        } catch {
            logger.error(
                "ServerWebSocketClient: failed to report capabilities",
                metadata: ["error": .stringConvertible(error.localizedDescription)]
            )
        }
    }

    // MARK: - Message Receiving

    private func receiveMessages() async {
        guard let task = webSocketTask else { return }

        while !isStopped {
            do {
                let message = try await task.receive()
                switch message {
                case let .string(text):
                    handleMessage(text)
                case let .data(data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleMessage(text)
                    }
                @unknown default:
                    break
                }
            } catch {
                guard !isStopped else { return }
                logger.warning(
                    "ServerWebSocketClient: receive error – scheduling reconnect",
                    metadata: ["error": .stringConvertible(error.localizedDescription)]
                )
                scheduleReconnect()
                return
            }
        }
    }

    // MARK: - Message Handling

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let envelope = try? JSONDecoder().decode(ServerSocketMessage.self, from: data)
        else { return }

        switch envelope.messageType {
        case "GeneralCommand":
            handleGeneralCommand(data)
        case "ForceKeepAlive":
            // The server sends ForceKeepAlive immediately after accepting the
            // WebSocket and attaching a WebSocketController to the session.
            // Reporting capabilities here (not at connect time) guarantees the
            // controller is already active, so SupportsMediaControl = true when
            // CapabilitiesChanged fires and the dashboard updates.
            if !capabilitiesReported {
                capabilitiesReported = true
                Task { [weak self] in await self?.reportCapabilities() }
            }
        case "KeepAlive":
            sendKeepAliveAck()
        default:
            break
        }
    }

    private func handleGeneralCommand(_ data: Data) {
        guard let msg = try? JSONDecoder().decode(GeneralCommandMessage.self, from: data),
              msg.data.name == "DisplayMessage"
        else { return }

        let args = msg.data.arguments ?? [:]
        let header = args["Header"]
        let body = args["Text"] ?? ""
        let timeout = args["TimeoutMs"].flatMap(Double.init).map { $0 / 1000 } ?? 5

        serverMessageProxy.present(header: header, body: body, timeout: timeout)

        logger.debug(
            "ServerWebSocketClient: received DisplayMessage",
            metadata: [
                "header": .stringConvertible(header ?? ""),
                "body": .stringConvertible(body),
            ]
        )
    }

    private func sendKeepAliveAck() {
        webSocketTask?.send(.string(#"{"MessageType":"KeepAlive"}"#)) { [weak self] error in
            if let error {
                self?.logger.warning(
                    "ServerWebSocketClient: KeepAlive send failed",
                    metadata: ["error": .stringConvertible(error.localizedDescription)]
                )
            }
        }
    }

    // MARK: - Reconnection

    private func scheduleReconnect() {
        guard !isStopped else { return }

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        webSocketSession?.invalidateAndCancel()
        webSocketSession = nil

        reconnectTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard let self, !self.isStopped else { return }
            self.openConnection()
        }
    }
}
