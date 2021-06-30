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

class InfoTabBarViewController: UITabBarController, UIGestureRecognizerDelegate {

    var videoPlayer: VideoPlayerViewController?
    var subtitleViewController: SubtitlesViewController?
    var audioViewController: AudioViewController?
    var mediaInfoController: MediaInfoViewController?
    var infoContainerPos: CGRect?
    var tabBarHeight: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        mediaInfoController = MediaInfoViewController()
        audioViewController = AudioViewController()
        subtitleViewController = SubtitlesViewController()

        viewControllers = [mediaInfoController!, audioViewController!, subtitleViewController!]

        tabBarHeight = tabBar.frame.size.height

        tabBar.standardAppearance.backgroundColor = .clear
        tabBar.standardAppearance.backgroundImage = UIImage()
        tabBar.standardAppearance.backgroundEffect = .none
        tabBar.barTintColor = .clear

    }

    func setupInfoViews(mediaItem: BaseItemDto, subtitleTracks: [Subtitle], selectedSubtitleTrack: Int32, audioTracks: [AudioTrack], selectedAudioTrack: Int32, delegate: VideoPlayerSettingsDelegate) {

        mediaInfoController?.setMedia(item: mediaItem)

        audioViewController?.prepareAudioView(audioTracks: audioTracks, selectedTrack: selectedAudioTrack, delegate: delegate)

        subtitleViewController?.prepareSubtitleView(subtitleTracks: subtitleTracks, selectedTrack: selectedSubtitleTrack, delegate: delegate)

        if let videoPlayer = videoPlayer {
            infoContainerPos = CGRect(x: 88, y: 87, width: videoPlayer.infoViewContainer.frame.width, height: videoPlayer.infoViewContainer.frame.height)

        }

    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let pos = infoContainerPos else {
            return
        }

        switch item.title {
        case "Audio":
            if var height = audioViewController?.height {
                height += tabBarHeight
                UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) { [self] in
                    videoPlayer?.infoViewContainer.frame = CGRect(x: pos.minX, y: pos.minY, width: pos.width, height: height)

                }

            }
            break
        case "Info":
            if var height = mediaInfoController?.height {
                height += tabBarHeight
                UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) { [self] in
                    videoPlayer?.infoViewContainer.frame = CGRect(x: pos.minX, y: pos.minY, width: pos.width, height: height)

                }

            }
             break
        case "Subtitles":
            if var height = subtitleViewController?.height {
                height += tabBarHeight
                UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) { [self] in
                    videoPlayer?.infoViewContainer.frame = CGRect(x: pos.minX, y: pos.minY, width: pos.width, height: height)

                }

            }
            break
        default:
            break
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
