//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// TODO: sync watch state back to the server when online

extension DownloadManager {

    func setIsPlayed(_ isPlayed: Bool, for id: String) -> UserItemDataDto? {
        guard let task = task(id: id) else { return nil }

        if task.isContainer {
            for media in downloadedEpisodes(under: id) {
                setUserData(for: media.id) { userData in
                    userData.isPlayed = isPlayed
                    userData.playbackPositionTicks = 0
                    userData.playedPercentage = nil
                }
            }
        }

        let result = setUserData(for: id) { userData in
            userData.isPlayed = isPlayed

            if isPlayed {
                userData.playbackPositionTicks = 0
                userData.playedPercentage = nil
            }
        }

        refreshContainerUnplayedCounts()

        return result
    }

    func setIsFavorite(_ isFavorite: Bool, for id: String) -> UserItemDataDto? {
        setUserData(for: id) { $0.isFavorite = isFavorite }
    }

    func refreshContainerUnplayedCounts() {
        for container in tasks.filter(\.isContainer) {
            let media = downloadedEpisodes(under: container.id)
            let unplayedCount = media.count(where: { $0.item.userData?.isPlayed != true })
            let isPlayed = media.isNotEmpty && unplayedCount == 0

            let current = container.item.userData
            guard current?.unplayedItemCount != unplayedCount || (current?.isPlayed ?? false) != isPlayed else { continue }

            setUserData(for: container.id) { userData in
                userData.unplayedItemCount = unplayedCount
                userData.isPlayed = isPlayed
            }
        }
    }

    @discardableResult
    private func setUserData(
        for id: String,
        notify: Bool = true,
        _ mutator: (inout UserItemDataDto) -> Void
    ) -> UserItemDataDto? {
        guard task(id: id) != nil else { return nil }

        update(id: id) { task in
            var userData = task.item.userData ?? UserItemDataDto()
            userData.itemID = id
            mutator(&userData)
            task.item.userData = userData
        }

        guard let userData = task(id: id)?.item.userData else { return nil }

        if notify {
            Notifications[.itemUserDataDidChange].post(userData)
        }

        return userData
    }

    // MARK: - Playback session

    func reportPlaybackProgress(for id: String, seconds: Duration?) {
        guard let ticks = seconds?.ticks else { return }
        let runtime = playbackRuntime(for: id)

        setUserData(for: id, notify: false) { userData in
            userData.playbackPositionTicks = ticks

            if let runtime, runtime > 0 {
                userData.playedPercentage = Double(ticks) / Double(runtime) * 100
            }
        }
    }

    func reportPlaybackStopped(for id: String, seconds: Duration?) {
        guard let ticks = seconds?.ticks else { return }
        let runtime = playbackRuntime(for: id)

        setUserData(for: id) { userData in
            if let runtime, runtime > 0, Double(ticks) / Double(runtime) >= 0.9 {
                userData.isPlayed = true
                userData.playbackPositionTicks = 0
                userData.playedPercentage = nil
            } else {
                userData.playbackPositionTicks = ticks

                if let runtime, runtime > 0 {
                    userData.playedPercentage = Double(ticks) / Double(runtime) * 100
                }
            }
        }

        refreshContainerUnplayedCounts()
    }

    private func playbackRuntime(for id: String) -> Int? {
        guard let item = task(id: id)?.item else { return nil }
        return item.runTimeTicks ?? item.mediaSources?.first?.runTimeTicks
    }
}
