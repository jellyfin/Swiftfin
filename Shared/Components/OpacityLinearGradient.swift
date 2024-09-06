//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OpacityLinearGradient: View {

    typealias Stop = (location: CGFloat, opacity: CGFloat)

    private let stops: [Stop]

    init(@ArrayBuilder<Stop> stops: () -> [Stop]) {
        self.stops = stops()
    }

//    private var convertedStops: [Gradient.Stop] {
//        stops.map { stop in
//            if stop.opacity == 0.0 {
//                return Gradient.Stop(
//                    color: Color.clear,
//                    location: stop.location
//                )
//            } else {
//                return Gradient.Stop(
//                    color: Color.black.opacity(stop.opacity),
//                    location: stop.location
//                )
//            }
//        }
//    }

    var body: some View {
        Rectangle()
            .mask {
                LinearGradient(
                    stops: stops.map {
                        Gradient.Stop(
                            color: Color.black.opacity($0.opacity),
                            location: $0.location
                        )
                    },
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }
}
