//
//  LazyImage++.swift
//  JellyfinPlayer
//
//  Created by PangMo5 on 2021/06/02.
//

import Foundation
import SwiftUI
import NukeUI

extension LazyImage {
    func placeholderAndFailure<Content: View>(@ViewBuilder _ content: () -> Content?) -> LazyImage {
        placeholder {
            content()
        }
        .failure {
            content()
        }
    }

}
