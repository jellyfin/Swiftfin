//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

/// Utility for views that are passed a `Binding` that
/// may not be able to respond to view updates from
/// the source
class BindingBox<Wrapped>: ObservableObject {

    @Published
    var value: Wrapped

    private let source: Binding<Wrapped>
    private var valueObserver: AnyCancellable!

    init(source: Binding<Wrapped>) {
        self.source = source
        self.value = source.wrappedValue
        valueObserver = nil

        valueObserver = $value.sink { [weak self] in
            self?.source.wrappedValue = $0
        }
    }
}
