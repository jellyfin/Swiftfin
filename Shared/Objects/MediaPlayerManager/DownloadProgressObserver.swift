//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import FactoryKit
import Foundation
import JellyfinAPI

class DownloadProgressObserver: ViewModel, MediaPlayerObserver {

    weak var manager: MediaPlayerManager? {
        didSet {
            if let manager {
                setup(with: manager)
            }
        }
    }

    private let timer = PokeIntervalTimer()
    private var item: MediaPlayerItem?

    @Injected(\.downloadManager)
    private var downloadManager

    init(item: MediaPlayerItem) {
        self.item = item
        super.init()
    }

    private func setup(with manager: MediaPlayerManager) {
        cancellables = []

        timer.sink { [weak self] in
            self?.sendProgress()
            self?.timer.poke()
        }
        .store(in: &cancellables)

        manager.actions
            .sink { [weak self] in self?.didReceive(action: $0) }
            .store(in: &cancellables)

        manager.$playbackItem
            .sink { [weak self] in self?.playbackItemDidChange($0) }
            .store(in: &cancellables)

        manager.$playbackRequestStatus
            .sink { [weak self] _ in self?.timer.poke() }
            .store(in: &cancellables)

        Notifications[.applicationWillTerminate]
            .publisher
            .sink { [weak self] _ in self?.endPlaybackSession() }
            .store(in: &cancellables)
    }

    private func sendProgress() {
        guard let item, let itemID = item.baseItem.id else { return }
        downloadManager.reportPlaybackProgress(for: itemID, seconds: manager?.seconds)
    }

    private func endPlaybackSession() {
        guard let item, let itemID = item.baseItem.id else { return }
        downloadManager.reportPlaybackStopped(for: itemID, seconds: manager?.seconds)
    }

    private func playbackItemDidChange(_ newItem: MediaPlayerItem?) {
        timer.poke()

        if let item, newItem !== item {
            endPlaybackSession()
            self.item = newItem?.baseItem.isDownloaded == true ? newItem : nil
        }
    }

    private func didReceive(action: MediaPlayerManager._Action) {
        switch action {
        case .stop:
            endPlaybackSession()
            timer.stop()
            cancellables = []
            item = nil
        default: ()
        }
    }
}
