//
//  ItemView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/10/21.
//

import SwiftUI
import Introspect

struct ItemView: View {
    var item: ResumeItem;
    
    init(item: ResumeItem) {
        self.item = item;
    }
    
    var body: some View {
        Group {
            NavigationLink(destination: EmptyView(), label: {})
            NavigationLink(destination: EmptyView(), label: {})
            if(item.Type == "Movie") {
                MovieItemView(item: self.item)
            } else if(item.Type == "Season") {
                SeasonItemView(item: self.item)
            } else if(item.Type == "Series") {
                SeriesItemView(item: self.item)
            } else if(item.Type == "Episode") {
                EpisodeItemView(item: self.item)
            } else {
                Text("Type: \(item.Type) not implemented yet :(")
            }
        }
        .introspectTabBarController { (UITabBarController) in
                    UITabBarController.tabBar.isHidden = false
        }
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(false)
        .statusBar(hidden: false)
        .prefersHomeIndicatorAutoHidden(false)
        .preferredColorScheme(.none)
        .edgesIgnoringSafeArea([])
        .overrideViewPreference(.unspecified)
        .supportedOrientations(.allButUpsideDown)
    }
}
