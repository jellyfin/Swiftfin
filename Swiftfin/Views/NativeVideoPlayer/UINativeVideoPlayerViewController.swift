//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import AVKit
import Combine
import Defaults
import JellyfinAPI
import SwiftUI

class UINativeVideoPlayerViewController: AVPlayerViewController {

    private let manager: MediaPlayerManager
    private let proxy: AVPlayerVideoPlayerProxy

    private var managerEventObserver: AnyCancellable!
    private var rateObserver: NSKeyValueObservation!
    private var timeObserver: Any!

    init(manager: MediaPlayerManager) {

        let videoPlayerProxy = AVPlayerVideoPlayerProxy()
        manager.proxy = videoPlayerProxy

        self.proxy = videoPlayerProxy
        self.manager = manager

        super.init(nibName: nil, bundle: nil)

        let newPlayer: AVPlayer = .init()

        newPlayer.allowsExternalPlayback = true
        newPlayer.appliesMediaSelectionCriteriaAutomatically = false

        allowsPictureInPicturePlayback = true
        updatesNowPlayingInfoCenter = false

        timeObserver = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1000),
            queue: .main
        ) { newTime in
            print(newTime)
//            Task {
//                await manager.send(.seek(seconds: newTime.seconds))
//            }
        }

        rateObserver = newPlayer.observe(\.rate, options: [.new, .initial]) { _, value in
            if let rate = value.newValue {
                print(rate)
            }
        }

        player = newPlayer
        videoPlayerProxy.avPlayer = player

        if let playbackItem = manager.playbackItem {
            playNew(playbackItem: playbackItem)
        }

        managerEventObserver = manager.events
            .sink { event in
                switch event {
                case .playbackStopped:
                    self.dismiss(animated: true)
                case let .playNew(playbackItem):
                    self.playNew(playbackItem: playbackItem)
                }
            }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        proxy.stop()

        guard let timeObserver else { return }
        player?.removeTimeObserver(timeObserver)
    }

    private func playNew(playbackItem: MediaPlayerItem) {

        let newAVPlayerItem = AVPlayerItem(url: playbackItem.url)

        player?.replaceCurrentItem(with: newAVPlayerItem)
        player?.currentItem?.externalMetadata = createAVMetadata(for: playbackItem.baseItem)

        seek(to: playbackItem.baseItem.startTimeSeconds)
    }

    // TODO: get metadata from playback item
    private func createAVMetadata(for item: BaseItemDto) -> [AVMetadataItem] {
        let title: String
        var subtitle: String? = nil
        let description = item.overview

        if item.type == .episode,
           let seriesName = item.seriesName
        {
            title = seriesName
            subtitle = item.displayTitle
        } else {
            title = item.displayTitle
        }

        return [
            AVMetadataIdentifier.commonIdentifierTitle: title,
            .iTunesMetadataTrackSubTitle: subtitle,
            .commonIdentifierDescription: description,
        ]
            .compactMap(createMetadataItem)
    }

    private func createMetadataItem(
        for identifier: AVMetadataIdentifier,
        value: Any?
    ) -> AVMetadataItem? {
        guard let value else { return nil }

        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"

        return item.copy() as? AVMetadataItem
    }

    private func seek(to seconds: TimeInterval) {
        player?.seek(
            to: CMTime(seconds: seconds, preferredTimescale: 1),
            toleranceBefore: .zero,
            toleranceAfter: .zero,
            completionHandler: { _ in
                self.proxy.play()
            }
        )
    }
}
