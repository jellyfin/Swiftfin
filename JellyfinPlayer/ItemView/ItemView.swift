/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import Introspect
import JellyfinAPI

class VideoPlayerItem: ObservableObject {
    @Published var shouldShowPlayer: Bool = false
    @Published var itemToPlay: BaseItemDto = BaseItemDto()
}

struct ItemView: View {

    @State private var videoIsLoading: Bool = false; // This variable is only changed by the underlying VLC view.
    @State private var viewDidLoad: Bool = false
    @State private var orientation: UIDeviceOrientation = .unknown
    @StateObject private var videoPlayerItem: VideoPlayerItem = VideoPlayerItem()
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass
    
    private let viewModel: DetailItemViewModel
    
    init(item: BaseItemDto) {
        self.viewModel = DetailItemViewModel(item: item)
    }

    var body: some View {
        if hSizeClass == .compact && vSizeClass == .regular {
            ItemPortraitBodyView(videoIsLoading: $videoIsLoading,
                                 portraitHeaderView: { viewModel in
                                    ImageView(src: viewModel.item.getBackdropImage(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 622 : Int(UIScreen.main.bounds.width)),
                                              bh: viewModel.item.getBackdropImageBlurHash())
                                        .opacity(0.4)
                                        .blur(radius: 2.0)
                                 },
                                 portraitStaticOverlayView: { viewModel in
                                    PortraitHeaderOverlayView()
                                        .environmentObject(viewModel)
                                 })
                .environmentObject(videoPlayerItem)
                .environmentObject(viewModel)
        } else {
            Text("Hello there")
        }
    }
}
