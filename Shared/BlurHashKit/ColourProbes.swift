//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

public extension BlurHash {
    func linearRGB(atX x: Float) -> (Float, Float, Float) {
        return components[0].enumerated().reduce((0, 0, 0)) { sum, horizontalEnumerated -> (Float, Float, Float) in
            let (i, component) = horizontalEnumerated
            return sum + component * cos(Float.pi * Float(i) * x)
        }
    }

    func linearRGB(atY y: Float) -> (Float, Float, Float) {
        return components.enumerated().reduce((0, 0, 0)) { sum, verticalEnumerated in
            let (j, horizontalComponents) = verticalEnumerated
            return sum + horizontalComponents[0] * cos(Float.pi * Float(j) * y)
        }
    }

    func linearRGB(at position: (Float, Float)) -> (Float, Float, Float) {
        return components.enumerated().reduce((0, 0, 0)) { sum, verticalEnumerated in
            let (j, horizontalComponents) = verticalEnumerated
            return horizontalComponents.enumerated().reduce(sum) { sum, horizontalEnumerated in
                let (i, component) = horizontalEnumerated
                return sum + component * cos(Float.pi * Float(i) * position.0) * cos(Float.pi * Float(j) * position.1)
            }
        }
    }

    func linearRGB(from upperLeft: (Float, Float), to lowerRight: (Float, Float)) -> (Float, Float, Float) {
        return components.enumerated().reduce((0, 0, 0)) { sum, verticalEnumerated in
            let (j, horizontalComponents) = verticalEnumerated
            return horizontalComponents.enumerated().reduce(sum) { sum, horizontalEnumerated in
                let (i, component) = horizontalEnumerated
                let horizontalAverage: Float = i == 0 ? 1 :
                    (sin(Float.pi * Float(i) * lowerRight.0) - sin(Float.pi * Float(i) * upperLeft.0)) /
                    (Float(i) * Float.pi * (lowerRight.0 - upperLeft.0))
                let veritcalAverage: Float = j == 0 ? 1 :
                    (sin(Float.pi * Float(j) * lowerRight.1) - sin(Float.pi * Float(j) * upperLeft.1)) /
                    (Float(j) * Float.pi * (lowerRight.1 - upperLeft.1))
                return sum + component * horizontalAverage * veritcalAverage
            }
        }
    }

    func linearRGB(at upperLeft: (Float, Float), size: (Float, Float)) -> (Float, Float, Float) {
        return linearRGB(from: upperLeft, to: (upperLeft.0 + size.0, upperLeft.1 + size.1))
    }

    var averageLinearRGB: (Float, Float, Float) {
        return components[0][0]
    }

    var leftEdgeLinearRGB: (Float, Float, Float) { return linearRGB(atX: 0) }
    var rightEdgeLinearRGB: (Float, Float, Float) { return linearRGB(atX: 1) }
    var topEdgeLinearRGB: (Float, Float, Float) { return linearRGB(atY: 0) }
    var bottomEdgeLinearRGB: (Float, Float, Float) { return linearRGB(atY: 1) }
    var topLeftCornerLinearRGB: (Float, Float, Float) { return linearRGB(at: (0, 0)) }
    var topRightCornerLinearRGB: (Float, Float, Float) { return linearRGB(at: (1, 0)) }
    var bottomLeftCornerLinearRGB: (Float, Float, Float) { return linearRGB(at: (0, 1)) }
    var bottomRightCornerLinearRGB: (Float, Float, Float) { return linearRGB(at: (1, 1)) }
}

public extension BlurHash {
    func isDark(linearRGB rgb: (Float, Float, Float), threshold: Float = 0.3) -> Bool {
        rgb.0 * 0.299 + rgb.1 * 0.587 + rgb.2 * 0.114 < threshold
    }

    func isDark(threshold: Float = 0.3) -> Bool { isDark(linearRGB: averageLinearRGB, threshold: threshold) }

    func isDark(atX x: Float, threshold: Float = 0.3) -> Bool { isDark(linearRGB: linearRGB(atX: x), threshold: threshold) }
    func isDark(atY y: Float, threshold: Float = 0.3) -> Bool { isDark(linearRGB: linearRGB(atY: y), threshold: threshold) }
    func isDark(
        at position: (Float, Float),
        threshold: Float = 0.3
    ) -> Bool { isDark(linearRGB: linearRGB(at: position), threshold: threshold) }
    func isDark(
        from upperLeft: (Float, Float),
        to lowerRight: (Float, Float),
        threshold: Float = 0.3
    ) -> Bool { isDark(linearRGB: linearRGB(from: upperLeft, to: lowerRight), threshold: threshold) }
    func isDark(
        at upperLeft: (Float, Float),
        size: (Float, Float),
        threshold: Float = 0.3
    ) -> Bool { isDark(linearRGB: linearRGB(at: upperLeft, size: size), threshold: threshold) }

    var isLeftEdgeDark: Bool { isDark(atX: 0) }
    var isRightEdgeDark: Bool { isDark(atX: 1) }
    var isTopEdgeDark: Bool { isDark(atY: 0) }
    var isBottomEdgeDark: Bool { isDark(atY: 1) }
    var isTopLeftCornerDark: Bool { isDark(at: (0, 0)) }
    var isTopRightCornerDark: Bool { isDark(at: (1, 0)) }
    var isBottomLeftCornerDark: Bool { isDark(at: (0, 1)) }
    var isBottomRightCornerDark: Bool { isDark(at: (1, 1)) }
}
