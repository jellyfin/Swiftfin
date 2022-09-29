//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class PlaybackManager {

    private var cancellables = Set<AnyCancellable>()

    func sendStartReport(
        _ request: ReportPlaybackStartRequest,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        PlaystateAPI.reportPlaybackStart(reportPlaybackStartRequest: request)
            .sink { completion in
                switch completion {
                case .finished:
                    onSuccess()
                case let .failure(error):
                    onFailure(error)
                }
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
    }

    func sendProgressReport(
        _ request: ReportPlaybackProgressRequest,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        PlaystateAPI.reportPlaybackProgress(reportPlaybackProgressRequest: request)
            .sink { completion in
                switch completion {
                case .finished:
                    onSuccess()
                case let .failure(error):
                    onFailure(error)
                }
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
    }

    func sendStopReport(
        _ request: ReportPlaybackStoppedRequest,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        PlaystateAPI.reportPlaybackStopped(reportPlaybackStoppedRequest: request)
            .sink { completion in
                switch completion {
                case .finished:
                    onSuccess()
                case let .failure(error):
                    onFailure(error)
                }
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
    }
}
