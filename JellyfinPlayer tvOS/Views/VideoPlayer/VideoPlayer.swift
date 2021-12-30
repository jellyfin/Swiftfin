//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Stinsen
import SwiftUI
import JellyfinAPI

struct VideoPlayerView: UIViewControllerRepresentable {
    @EnvironmentObject var router: VideoPlayerCoordinator.Router

    var item: BaseItemDto
    
    func makeUIViewController(context: Context) -> some UIViewController {

        let storyboard = UIStoryboard(name: "VideoPlayer", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "VideoPlayer") as! VideoPlayerViewController
        viewController.manifest = item
        viewController.backAction = {
            self.router.dismissCoordinator()
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}
