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

    enum Event {
        case commandSent
        case messageSent
        case error(Error)
    }

    enum Action: Equatable {
        case command(SendGeneralCommand)
        case playState(SendPlaystateCommand)
        case message(String)
    }

    enum State: Hashable {
        case initial
        case connected
        case error(String)
    }

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

    init(_ session: SessionInfoDto) {
        self.session = session
    }

    func respond(to action: Action) -> State {
        currentTask?.cancel()

        switch action {
        case let .command(command):
            currentTask = Task {
                do {
                    try await sendGeneralCommand(command)
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
                    try await sendPlaystateCommand(command)
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

    // MARK: - Send General Command

    private func sendGeneralCommand(_ SendCommand: SendGeneralCommand) async throws {
        let generalCommand = SendCommand.toGeneralCommand(userID: userSession.user.id)

        guard let sessionID = session.id,
              let commandName = generalCommand.name,
              session.supportedCommands?.contains(commandName) == true
        else {
            throw JellyfinAPIError("Command not supported")
        }

        let request: Request<Void>

        if let arguments = generalCommand.arguments {
            request = Paths.sendFullGeneralCommand(sessionID: sessionID, generalCommand)
        } else {
            request = Paths.sendGeneralCommand(sessionID: sessionID, command: generalCommand.name?.rawValue ?? "")
        }

        _ = try await userSession.client.send(request)
    }

    // MARK: - Send Playstate Command

    private func sendPlaystateCommand(_ SendCommand: SendPlaystateCommand) async throws {
        guard let sessionID = session.id,
              session.isSupportsMediaControl == true
        else {
            throw JellyfinAPIError("PlayState command not supported")
        }

        let playstateRequest = SendCommand.toPlaystateRequest(userID: userSession.user.id)

        let request = Paths.sendPlaystateCommand(
            sessionID: sessionID,
            command: playstateRequest.command?.rawValue ?? "",
            seekPositionTicks: playstateRequest.seekPositionTicks,
            controllingUserID: playstateRequest.controllingUserID
        )

        _ = try await userSession.client.send(request)
    }

    // MARK: - Send Message

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
