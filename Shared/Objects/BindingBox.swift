//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

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

    private let source: Binding<Wrapped>?
    private var valueObserver: AnyCancellable!

    init(source: Binding<Wrapped>) {
        self.source = source
        self.value = source.wrappedValue
        valueObserver = nil

        valueObserver = $value.sink { [weak self] in
            self?.source?.wrappedValue = $0
        }
    }

    init(initialValue: Wrapped) {
        source = nil
        value = initialValue
        valueObserver = nil
    }
}
