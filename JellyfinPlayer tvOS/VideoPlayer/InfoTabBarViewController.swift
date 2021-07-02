//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import TVUIKit
import JellyfinAPI

class InfoTabViewController: UIViewController {
    var height: CGFloat = 420
}

class InfoTabBarViewController: UITabBarController, UIGestureRecognizerDelegate {

    var videoPlayer: VideoPlayerViewController?
    var subtitleViewController: SubtitlesViewController?
    var audioViewController: AudioViewController?
    var mediaInfoController: MediaInfoViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        mediaInfoController = MediaInfoViewController()
        audioViewController = AudioViewController()
        subtitleViewController = SubtitlesViewController()

        viewControllers = [mediaInfoController!, audioViewController!, subtitleViewController!]

    }

    func setupInfoViews(mediaItem: BaseItemDto, subtitleTracks: [Subtitle], selectedSubtitleTrack: Int32, audioTracks: [AudioTrack], selectedAudioTrack: Int32, delegate: VideoPlayerSettingsDelegate) {

        mediaInfoController?.setMedia(item: mediaItem)

        audioViewController?.prepareAudioView(audioTracks: audioTracks, selectedTrack: selectedAudioTrack, delegate: delegate)

        subtitleViewController?.prepareSubtitleView(subtitleTracks: subtitleTracks, selectedTrack: selectedSubtitleTrack, delegate: delegate)

    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {

        if let index = tabBar.items?.firstIndex(of: item),
           let tabViewController = viewControllers?[index] as? InfoTabViewController,
           let width = videoPlayer?.infoPanelContainerView.frame.width {
            let height = tabViewController.height + tabBar.frame.size.height
            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) { [self] in
                videoPlayer?.infoPanelContainerView.frame = CGRect(x: 88, y: 87, width: width, height: height)
            }
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
