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
