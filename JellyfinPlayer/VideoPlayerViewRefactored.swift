//
//  VideoPlayerViewRefactored.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/26/21.
//

import SwiftUI
import MobileVLCKit
import Introspect

struct VideoPlayerViewRefactored: View {
    @State private var shouldShowLoadingView: Bool = true;
    
    var body: some View {
        LoadingView(isShowing: $shouldShowLoadingView) {
            Text("content")
            .introspectTabBarController { (UITabBarController) in
                        UITabBarController.tabBar.isHidden = true
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .statusBar(hidden: true)
        .prefersHomeIndicatorAutoHidden(true)
        .preferredColorScheme(.dark)
        .edgesIgnoringSafeArea(.all)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .overrideViewPreference(.unspecified)
        .supportedOrientations(.landscape)
    }
}
