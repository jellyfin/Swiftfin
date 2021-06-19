//
//  VideoPlayer.swift
//  CustomPlayer
//
//  Created by Stephen Byatt on 25/5/21.
//

import SwiftUI

struct VideoPlayerView: UIViewControllerRepresentable {
        
    func makeUIViewController(context: Context) -> some UIViewController {
        
        let storyboard = UIStoryboard(name: "VideoPlayerStoryboard", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "VideoPlayer") as! VideoPlayerViewController
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
