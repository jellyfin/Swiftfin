//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

// TODO: rename `PublishedBox`, remove other implementation

/// Utility class to act as an intermediary for a `Binding` value or
/// the source of a single value where `State` is not appropriate.
///
/// Useful when:
/// - a view is passed a `Binding` that may not be able
///   to respond to view updates from the source
/// - the source of information that would typically be in a `State`
///   variable, or other publishing source, cause view update issues
class BindingBox<Wrapped>: ObservableObject {

    @Published
    var value: Wrapped

    private var source: Binding<Wrapped>?
    private var valueObserver: AnyCancellable!

    init(source: Binding<Wrapped>) {
        self.source = source
        self.value = source.wrappedValue
        valueObserver = nil

        valueObserver = $value
            .assign(to: source)
    }

    init(initialValue: Wrapped) {
        source = nil
        value = initialValue
        valueObserver = nil
    }
}

extension Publisher where Failure == Never {

    func assign(to binding: Binding<Output>) -> AnyCancellable {
        self.sink { value in
            binding.wrappedValue = value
        }
    }
}
