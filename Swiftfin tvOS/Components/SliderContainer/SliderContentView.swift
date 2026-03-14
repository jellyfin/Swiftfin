//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol SliderContentView: View {

    associatedtype Value: BinaryFloatingPoint

    /// The current state of the slider container.
    /// Receive this object as an environment object.
    var sliderState: SliderContainerState<Value> { get }
}
