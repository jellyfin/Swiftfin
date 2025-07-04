//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Get
import JellyfinAPI
import URLQueryEncoder

final class SessionManagerViewModel: ViewModel, Eventful, Stateful {

    // MARK: - Event

    enum Event {
        case commandSent
        case messageSent
        case error(Error)
    }

    // MARK: - Action

    enum Action: Equatable {
        case command(GeneralCommandType, GeneralCommandArgument? = nil)
        case playState(PlaystateCommand)
        case seek(positionTicks: Int64)
        case message(String)
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case connected
        case error(String)
    }

    // MARK: - Published Properties

    @Published
    var session: SessionInfoDto

    @Published
    var state: State = .initial

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var currentTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    // MARK: - Init

    init(_ session: SessionInfoDto) {
        self.session = session
    }

    // MARK: - Respond

    func respond(to action: Action) -> State {
        currentTask?.cancel()

        switch action {
        case let .command(type, arguments):
            currentTask = Task {
                do {
                    try await sendGeneralCommand(type: type, arguments: arguments?.arguments)
                    await MainActor.run {
                        self.eventSubject.send(.commandSent)
                        self.state = .connected
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(error))
                        self.state = .error(error.localizedDescription)
                    }
                }
            }.asAnyCancellable()

            return .connected

        case let .playState(command):
            currentTask = Task {
                do {
                    try await sendPlaystateCommand(command: command)
                    await MainActor.run {
                        self.eventSubject.send(.commandSent)
                        self.state = .connected
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(error))
                        self.state = .error(error.localizedDescription)
                    }
                }
            }.asAnyCancellable()

            return .connected

        case let .seek(positionTicks):
            currentTask = Task {
                do {
                    try await sendPlaystateCommand(command: .seek, seekPositionTicks: Int(positionTicks))
                    await MainActor.run {
                        self.eventSubject.send(.commandSent)
                        self.state = .connected
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(error))
                        self.state = .error(error.localizedDescription)
                    }
                }
            }.asAnyCancellable()

            return .connected

        case let .message(message):
            currentTask = Task {
                do {
                    try await sendMessage(message)
                    await MainActor.run {
                        self.eventSubject.send(.messageSent)
                        self.state = .connected
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(error))
                        self.state = .error(error.localizedDescription)
                    }
                }
            }.asAnyCancellable()

            return state
        }
    }

    // MARK: - General Command

    private func sendGeneralCommand(type: GeneralCommandType, arguments: [String: String]?) async throws {
        guard let sessionID = session.id,
              session.supportedCommands?.contains(type) == true
        else {
            throw JellyfinAPIError("Command not supported")
        }

        let request: Request<Void>

        if let arguments = arguments {
            let generalCommand = GeneralCommand(
                arguments: arguments,
                controllingUserID: userSession.user.id,
                name: type
            )
            request = Paths.sendFullGeneralCommand(sessionID: sessionID, generalCommand)
        } else {
            request = Paths.sendGeneralCommand(sessionID: sessionID, command: type.rawValue)
        }

        _ = try await userSession.client.send(request)
    }

    // MARK: - PlayState Command

    private func sendPlaystateCommand(command: PlaystateCommand, seekPositionTicks: Int? = nil) async throws {
        guard let sessionID = session.id,
              session.isSupportsMediaControl == true
        else {
            throw JellyfinAPIError("PlayState command not supported")
        }

        let request = Paths.sendPlaystateCommand(
            sessionID: sessionID,
            command: command.rawValue,
            seekPositionTicks: seekPositionTicks,
            controllingUserID: userSession.user.id
        )

        _ = try await userSession.client.send(request)
    }

    // MARK: - Message Command

    private func sendMessage(_ message: String) async throws {
        guard let sessionID = session.id,
              session.supportedCommands?.contains(.displayMessage) == true
        else {
            throw JellyfinAPIError("Display message not supported")
        }

        let messageCommand = MessageCommand(
            header: "Message from \(userSession.user.username)",
            text: message,
            timeoutMs: 5000
        )

        let request = Paths.sendMessageCommand(sessionID: sessionID, messageCommand)
        _ = try await userSession.client.send(request)
    }
}
