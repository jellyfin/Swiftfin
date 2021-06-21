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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        mediaInfoController = MediaInfoViewController()
        audioViewController = AudioViewController()
        subtitleViewController = SubtitlesViewController()

        viewControllers = [mediaInfoController!, audioViewController!, subtitleViewController!]

    }
    
    func setupInfoViews(mediaItem: BaseItemDto, subtitleTracks: [Subtitle], selectedSubtitleTrack : Int32,  audioTracks: [AudioTrack], selectedAudioTrack: Int32, delegate: VideoPlayerSettingsDelegate) {
        
        mediaInfoController?.setMedia(item: mediaItem)
        
        audioViewController?.prepareAudioView(audioTracks: audioTracks, selectedTrack: selectedAudioTrack, delegate: delegate)
        
        subtitleViewController?.prepareSubtitleView(subtitleTracks: subtitleTracks, selectedTrack: selectedSubtitleTrack, delegate: delegate)
        
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
