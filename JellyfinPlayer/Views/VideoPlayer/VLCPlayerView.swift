//
 /*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import UIKit
import SwiftUI

struct VLCPlayerView: UIViewControllerRepresentable {
    
    let viewModel: VideoPlayerViewModel
    
    typealias UIViewControllerType = VLCPlayerViewController
    
    func makeUIViewController(context: Context) -> VLCPlayerViewController {
        
        return VLCPlayerViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: VLCPlayerViewController, context: Context) {
        
    }
}
