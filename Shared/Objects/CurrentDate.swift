//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

/// A property wrapper that publishes the current
/// date at periodic intervals
@propertyWrapper
struct CurrentDate: DynamicProperty {

    @ObservedObject
    private var observable: CurrentDataObserver

    var projectedValue: Binding<Date> {
        $observable.currentDate
    }

    var wrappedValue: Date {
        observable.currentDate
    }

    init(interval: TimeInterval = 1) {
        self.observable = .init(interval: interval)
    }

    mutating func update() {
        _observable.update()
    }
}

extension CurrentDate {

    class CurrentDataObserver: ObservableObject {

        @Published
        var currentDate: Date = .now

        private var publisher: AnyCancellable?

        init(interval: TimeInterval) {
            publisher = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    if let self {
                        self.currentDate = .now
                    }
                }
        }
    }
}
