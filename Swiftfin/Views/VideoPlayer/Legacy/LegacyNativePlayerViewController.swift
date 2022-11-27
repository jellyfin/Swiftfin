//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import AVKit
import Combine
import JellyfinAPI
import UIKit

class LegacyNativePlayerViewController: AVPlayerViewController {

    let viewModel: LegacyVideoPlayerViewModel

    var timeObserverToken: Any?

    var lastProgressTicks: Int64 = 0

    private var cancellables = Set<AnyCancellable>()

    init(viewModel: LegacyVideoPlayerViewModel) {

        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        let player: AVPlayer

        if let transcodedStreamURL = viewModel.transcodedStreamURL {
            player = AVPlayer(url: transcodedStreamURL)
        } else {
            player = AVPlayer(url: viewModel.hlsStreamURL)
        }

        player.appliesMediaSelectionCriteriaAutomatically = false

        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 5, preferredTimescale: timeScale)

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
            if time.seconds != 0 {
                self?.sendProgressReport(seconds: time.seconds)
            }
        }

        self.player = player

        self.allowsPictureInPicturePlayback = true
        self.player?.allowsExternalPlayback = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stop()
        removePeriodicTimeObserver()
    }

    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        player?.seek(
            to: CMTimeMake(value: viewModel.currentSecondTicks, timescale: 10_000_000),
            toleranceBefore: CMTimeMake(value: 1, timescale: 1),
            toleranceAfter: CMTimeMake(value: 1, timescale: 1),
            completionHandler: { _ in
                self.play()
            }
        )
    }

    private func play() {
        player?.play()
    }

    private func sendProgressReport(seconds: Double) {
        viewModel.setSeconds(Int64(seconds))
    }

    private func stop() {
        self.player?.pause()
    }
}
