//
//  VideoPlayerView.swift
//  JellyfinVideoPlayerDev
//
//  Created by Ethan Pippin on 11/12/21.
//

import UIKit
import SwiftUI

struct NativePlayerView: UIViewControllerRepresentable {
    
    let viewModel: VideoPlayerViewModel
    
    typealias UIViewControllerType = NativePlayerViewController
    
    func makeUIViewController(context: Context) -> NativePlayerViewController {
        
        return NativePlayerViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: NativePlayerViewController, context: Context) {
        
    }
}

struct VLCPlayerView: UIViewControllerRepresentable {
    
    let viewModel: VideoPlayerViewModel
    
    typealias UIViewControllerType = VLCPlayerViewController
    
    func makeUIViewController(context: Context) -> VLCPlayerViewController {
        
        return VLCPlayerViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: VLCPlayerViewController, context: Context) {
        
    }
}
