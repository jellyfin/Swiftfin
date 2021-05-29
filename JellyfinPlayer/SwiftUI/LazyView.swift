//
//  LazyView.swift
//  JellyfinPlayer
//
//  Created by PangMo5 on 2021/05/28.
//

import Foundation
import SwiftUI

struct LazyView<Content: View>: View {
    var content: () -> Content
    var body: some View {
        self.content()
    }
}
