//
//  InfoTabBarViewController.swift
//  CustomPlayer
//
//  Created by Stephen Byatt on 15/6/21.
//

import TVUIKit

class InfoTabBarViewController: UITabBarController, UIGestureRecognizerDelegate {
        
    var videoPlayer : VideoPlayerViewController? = nil
    var subtitleViewController : SubtitlesViewController? = nil
    var audioViewController : AudioViewController? = nil


    override func viewDidLoad() {
        super.viewDidLoad()
        
        for child in children {
            if let vc = child as? SubtitlesViewController {
                print("subtitle view added")
                subtitleViewController = vc
                subtitleViewController!.infoTabBar = self
            }
            if let vc = child as? AudioViewController {
                print("audio view added")
                audioViewController = vc
                audioViewController!.infoTabBar = self
            }
        }

        // Do any additional setup after loading the view.
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
