//
//  InfoTabBarViewController.swift
//  CustomPlayer
//
//  Created by Stephen Byatt on 15/6/21.
//

import TVUIKit
import JellyfinAPI

class InfoTabBarViewController: UITabBarController, UIGestureRecognizerDelegate {
        
    var videoPlayer : VideoPlayerViewController? = nil
    var subtitleViewController : SubtitlesViewController? = nil
    var audioViewController : AudioViewController? = nil
    var mediaInfoController : MediaInfoViewController? = nil
    var infoContainerPos : CGRect? = nil
    var tabBarHeight : CGFloat = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        mediaInfoController = MediaInfoViewController()
        audioViewController = AudioViewController()
        subtitleViewController = SubtitlesViewController()

        tabBarHeight = tabBar.frame.size.height
        
        
        viewControllers = [mediaInfoController!, audioViewController!, subtitleViewController!]

    }
    
    func setupInfoViews(mediaItem: BaseItemDto, subtitleTracks: [Subtitle], selectedSubtitleTrack : Int32,  audioTracks: [AudioTrack], selectedAudioTrack: Int32, delegate: VideoPlayerSettingsDelegate) {
        
        mediaInfoController?.setMedia(item: mediaItem)
        
        audioViewController?.prepareAudioView(audioTracks: audioTracks, selectedTrack: selectedAudioTrack, delegate: delegate)
        
        subtitleViewController?.prepareSubtitleView(subtitleTracks: subtitleTracks, selectedTrack: selectedSubtitleTrack, delegate: delegate)
        
        if let videoPlayer = videoPlayer {
            infoContainerPos = CGRect(x: 88, y: 57, width: videoPlayer.infoViewContainer.frame.width, height: videoPlayer.infoViewContainer.frame.height)
            
        }
        
       
        
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let pos = infoContainerPos else {
            return
        }
        
        print(item.title!)

        switch item.title {
        case "Audio":
            if var height = audioViewController?.height {
                print(height)

                height += tabBarHeight
                
                UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) { [self] in
                    videoPlayer?.infoViewContainer.frame = CGRect(x: pos.minX, y: pos.minY, width: pos.width, height: height)

                }

                
            }
            break
        case "Info":
            if var height = mediaInfoController?.height {
                print(height)

                height += tabBarHeight
                UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) { [self] in
                    videoPlayer?.infoViewContainer.frame = CGRect(x: pos.minX, y: pos.minY, width: pos.width, height: height)

                }

            }
             break
        case "Subtitles":
            if var height = subtitleViewController?.height{
                print(height)

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
   
        
    
    // MARK: - Navigation

//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destination.
//        // Pass the selected object to the new view controller.
//    }
//

}
