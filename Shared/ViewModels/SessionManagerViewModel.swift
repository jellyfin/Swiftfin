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

    // MARK: Event

    enum Event {
        case commandSent
        case messageSent
        case error(Error)
    }

    // MARK: Action

    enum Action: Equatable {
        case command(GeneralCommandType, GeneralCommandArgument? = nil)
        case playState(PlaystateCommand)
        case seek(positionTicks: Int64)
        case message(String)
    }

    // MARK: BackgroundState

    enum BackgroundState: Hashable {
        case sending
    }

    // MARK: State

    enum State: Hashable {
        case initial
        case connected
        case error(String)
    }

    @Published
    var session: SessionInfoDto

    @Published
    var backgroundStates: Set<BackgroundState> = []

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

    // MARK: - Response

    func respond(to action: Action) -> State {
        currentTask?.cancel()

        switch action {
        case let .command(type, arguments):
            currentTask = Task {
                if let arguments {
                    await sendCommand(type, arguments: arguments.arguments)
                } else {
                    await sendCommand(type, arguments: nil)
                }
            }.asAnyCancellable()
            return .connected
        case let .playState(command):
            currentTask = Task {
                await sendPlayStateCommand(command)
            }.asAnyCancellable()
            return .connected
        case let .seek(positionTicks):
            currentTask = Task {
                await sendSeekCommand(positionTicks)
            }.asAnyCancellable()
            return .connected
        case let .message(message):
            currentTask = Task {
                await sendMessage(message)
            }.asAnyCancellable()
            return state
        }
    }

    // MARK: - Send Command

    private func sendCommand(_ commandType: GeneralCommandType, arguments: [String: String]?) async {
        guard let sessionID = session.id,
              session.supportedCommands?.contains(commandType) == true
        else {
            await handleError(JellyfinAPIError("Command not supported"), errorMessage: "Command not supported")
            return
        }

        await setBackgroundState(.sending, active: true)

        do {
            let request: Request<Void>

            if let arguments = arguments {
                let generalCommand = GeneralCommand(
                    arguments: arguments,
                    controllingUserID: userSession.user.id,
                    name: commandType
                )
                request = Paths.sendFullGeneralCommand(sessionID: sessionID, generalCommand)
            } else {
                request = Paths.sendGeneralCommand(sessionID: sessionID, command: commandType.rawValue)
            }

            let _ = try await userSession.client.send(request)
            await handleSuccess(.commandSent)
        } catch {
            await handleError(error, errorMessage: error.localizedDescription)
        }
    }

    // MARK: - Send PlayState Command

    private func sendPlayStateCommand(_ command: PlaystateCommand) async {
        guard let sessionID = session.id,
              session.isSupportsMediaControl == true
        else {
            await handleError(JellyfinAPIError("PlayState command not supported"), errorMessage: "PlayState not supported")
            return
        }

        await setBackgroundState(.sending, active: true)

        do {
            let request = Paths.sendPlaystateCommand(
                sessionID: sessionID,
                command: command.rawValue,
                controllingUserID: userSession.user.id
            )

            let _ = try await userSession.client.send(request)
            await handleSuccess(.commandSent)
        } catch {
            await handleError(error, errorMessage: error.localizedDescription)
        }
    }

    // MARK: - Send Seek Command

    private func sendSeekCommand(_ positionTicks: Int64) async {
        guard let sessionID = session.id,
              session.isSupportsMediaControl == true
        else {
            await handleError(JellyfinAPIError("Seek command not supported"), errorMessage: "Seek not supported")
            return
        }

        await setBackgroundState(.sending, active: true)

        do {
            let request = Paths.sendPlaystateCommand(
                sessionID: sessionID,
                command: PlaystateCommand.seek.rawValue,
                seekPositionTicks: Int(positionTicks),
                controllingUserID: userSession.user.id
            )

            let _ = try await userSession.client.send(request)
            await handleSuccess(.commandSent)
        } catch {
            await handleError(error, errorMessage: error.localizedDescription)
        }
    }

    // MARK: - Send Message

    private func sendMessage(_ message: String) async {
        guard let sessionID = session.id,
              session.supportedCommands?.contains(.displayMessage) == true
        else {
            await handleError(JellyfinAPIError("Display message not supported"), errorMessage: "Message not supported")
            return
        }

        await setBackgroundState(.sending, active: true)

        do {
            let messageCommand = MessageCommand(
                header: "Message from \(userSession.user.username)",
                text: message,
                timeoutMs: 5000
            )

            let request = Paths.sendMessageCommand(sessionID: sessionID, messageCommand)
            let _ = try await userSession.client.send(request)
            await handleSuccess(.messageSent)
        } catch {
            await handleError(error, errorMessage: error.localizedDescription)
        }
    }

    // MARK: - State Management

    private func handleSuccess(_ event: Event) async {
        await MainActor.run {
            backgroundStates.remove(.sending)
            eventSubject.send(event)
            state = .connected
        }
    }

    private func handleError(_ error: Error, errorMessage: String) async {
        await MainActor.run {
            backgroundStates.remove(.sending)
            eventSubject.send(.error(error))
            state = .error(errorMessage)
        }
    }

    private func setBackgroundState(_ backgroundState: BackgroundState, active: Bool) async {
        await MainActor.run {
            if active {
                backgroundStates.insert(backgroundState)
            } else {
                backgroundStates.remove(backgroundState)
            }
        }
    }
}

// MARK: General Command Arguments

extension SessionManagerViewModel {

    enum GeneralCommandArgument: Equatable {
        case volume(Int)
        case audioStreamIndex(Int)
        case subtitleStreamIndex(Int)
        case key(String)
        case string(String)
        case repeatMode(RepeatMode)
        case playMediaSource(itemId: String, mediaSourceId: String? = nil, audioStreamIndex: Int? = nil, subtitleStreamIndex: Int? = nil)
        case playItems(itemIds: [String], startPositionTicks: Int64? = nil, playCommand: PlayCommand)
        case shuffleMode(Bool)
        case maxStreamingBitrate(Int64)
        case playbackOrder(PlaybackOrder)
        case displayContent(itemId: String, itemName: String, itemType: String)

        var arguments: [String: String] {
            switch self {
            case let .volume(value):
                return ["Volume": String(max(0, min(100, value)))]
            case let .audioStreamIndex(index):
                return ["Index": String(index)]
            case let .subtitleStreamIndex(index):
                return ["Index": String(index)]
            case let .key(key):
                return ["Key": key]
            case let .string(string):
                return ["String": string]
            case let .repeatMode(mode):
                return ["RepeatMode": mode.rawValue]
            case let .playMediaSource(itemId, mediaSourceId, audioStreamIndex, subtitleStreamIndex):
                var args = ["ItemId": itemId]
                if let mediaSourceId = mediaSourceId {
                    args["MediaSourceId"] = mediaSourceId
                }
                if let audioStreamIndex = audioStreamIndex {
                    args["AudioStreamIndex"] = String(audioStreamIndex)
                }
                if let subtitleStreamIndex = subtitleStreamIndex {
                    args["SubtitleStreamIndex"] = String(subtitleStreamIndex)
                }
                return args
            case let .playItems(itemIds, startPositionTicks, playCommand):
                var args = ["ItemIds": itemIds.joined(separator: ","), "PlayCommand": playCommand.rawValue]
                if let startPositionTicks = startPositionTicks {
                    args["StartPositionTicks"] = String(startPositionTicks)
                }
                return args
            case let .shuffleMode(shuffle):
                return ["ShuffleMode": shuffle ? "Shuffle" : "Sorted"]
            case let .maxStreamingBitrate(bitrate):
                return ["Bitrate": String(bitrate)]
            case let .playbackOrder(order):
                return ["PlaybackOrder": order.rawValue]
            case let .displayContent(itemId, itemName, itemType):
                return ["ItemId": itemId, "ItemName": itemName, "ItemType": itemType]
            }
        }
    }
}
