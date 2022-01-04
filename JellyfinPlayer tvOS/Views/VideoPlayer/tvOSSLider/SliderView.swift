//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI

struct SliderView: UIViewRepresentable {
    
    @ObservedObject var viewModel: VideoPlayerViewModel
    
    // TODO: look at adjusting value dependent on item runtime
    private let maxValue: Double = 1000
    
    func updateUIView(_ uiView: TvOSSlider, context: Context) {
        guard !viewModel.sliderIsScrubbing else { return }
        uiView.value = Float(maxValue * viewModel.sliderPercentage)
    }
    
    func makeUIView(context: Context) -> TvOSSlider {
        let slider = TvOSSlider(viewModel: viewModel)
        
        slider.minimumValue = 0
        slider.maximumValue = Float(maxValue)
        slider.value = Float(maxValue * viewModel.sliderPercentage)
        slider.thumbSize = 25
        slider.thumbTintColor = .white
        slider.minimumTrackTintColor = .white
        slider.focusScaleFactor = 1.4
        slider.panDampingValue = 50
        
        return slider
    }
}
