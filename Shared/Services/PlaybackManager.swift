//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI

final class PlaybackManager {

    static let service = Factory<PlaybackManager>(scope: .singleton) {
        .init()
    }

    private var cancellables = Set<AnyCancellable>()

//    func sendStartReport(
//        _ request: ReportPlaybackStartRequest,
//        onSuccess: @escaping () -> Void = {},
//        onFailure: @escaping (Error) -> Void = { _ in }
//    ) {
//        PlaystateAPI.reportPlaybackStart(reportPlaybackStartRequest: request)
//            .sink { completion in
//                switch completion {
//                case .finished:
//                    onSuccess()
//                case let .failure(error):
//                    onFailure(error)
//                }
//            } receiveValue: { _ in
//            }
//            .store(in: &cancellables)
//    }
//
//    func sendProgressReport(
//        _ request: ReportPlaybackProgressRequest,
//        onSuccess: @escaping () -> Void = {},
//        onFailure: @escaping (Error) -> Void = { _ in }
//    ) {
//        PlaystateAPI.reportPlaybackProgress(reportPlaybackProgressRequest: request)
//            .sink { completion in
//                switch completion {
//                case .finished:
//                    onSuccess()
//                case let .failure(error):
//                    onFailure(error)
//                }
//            } receiveValue: { _ in
//            }
//            .store(in: &cancellables)
//    }
//
//    func sendStopReport(
//        _ request: ReportPlaybackStoppedRequest,
//        onSuccess: @escaping () -> Void = {},
//        onFailure: @escaping (Error) -> Void = { _ in }
//    ) {
//        PlaystateAPI.reportPlaybackStopped(reportPlaybackStoppedRequest: request)
//            .sink { completion in
//                switch completion {
//                case .finished:
//                    onSuccess()
//                case let .failure(error):
//                    onFailure(error)
//                }
//            } receiveValue: { _ in
//            }
//            .store(in: &cancellables)
//    }
}
