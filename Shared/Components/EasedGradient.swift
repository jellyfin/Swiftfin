//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EasedGradient: View, ShapeStyle {

    enum Curve {
        case linear
        case easeIn
        case easeOut
        case easeInOut
        case smoothstep
        case smootherstep
        case power(Double)
        case cubicBezier(Double, Double, Double, Double)

        func value(at x: Double) -> Double {
            let x = x.clamped(to: 0 ... 1)

            switch self {
            case .linear:
                return x
            case .easeIn:
                return x * x
            case .easeOut:
                return 1 - ((1 - x) * (1 - x))
            case .easeInOut:
                return x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
            case .smoothstep:
                return x * x * (3 - 2 * x)
            case .smootherstep:
                return x * x * x * (x * (x * 6 - 15) + 10)
            case let .power(exponent):
                return pow(x, max(0.0001, exponent))
            case let .cubicBezier(x1, y1, x2, y2):
                return Self.cubicBezierY(forX: x, x1: x1, y1: y1, x2: x2, y2: y2)
            }
        }

        private static func cubicBezierY(
            forX x: Double,
            x1: Double,
            y1: Double,
            x2: Double,
            y2: Double
        ) -> Double {
            func sample(_ a1: Double, _ a2: Double, _ t: Double) -> Double {
                let a = 1 - 3 * a2 + 3 * a1
                let b = 3 * a2 - 6 * a1
                let c = 3 * a1
                return ((a * t + b) * t + c) * t
            }

            func derivative(_ a1: Double, _ a2: Double, _ t: Double) -> Double {
                let a = 1 - 3 * a2 + 3 * a1
                let b = 3 * a2 - 6 * a1
                let c = 3 * a1
                return (3 * a * t + 2 * b) * t + c
            }

            var t = x

            for _ in 0 ..< 8 {
                let dx = sample(x1, x2, t) - x
                let slope = derivative(x1, x2, t)

                guard abs(slope) > 0.000001 else { break }
                t = (t - dx / slope).clamped(to: 0 ... 1)
            }

            return sample(y1, y2, t).clamped(to: 0 ... 1)
        }
    }

    var startPoint: UnitPoint
    var endPoint: UnitPoint
    var curve: Curve
    var samples: Int

    private var stops: [Gradient.Stop]

    init(
        gradient: Gradient,
        startPoint: UnitPoint,
        endPoint: UnitPoint,
        curve: Curve = .smoothstep,
        samples: Int = 32
    ) {
        self.stops = gradient.stops
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.curve = curve
        self.samples = max(2, samples)
    }

    init(
        colors: [Color],
        startPoint: UnitPoint,
        endPoint: UnitPoint,
        curve: Curve = .smoothstep,
        samples: Int = 32
    ) {
        self.init(
            gradient: Gradient(colors: colors),
            startPoint: startPoint,
            endPoint: endPoint,
            curve: curve,
            samples: samples
        )
    }

    init(
        stops: [Gradient.Stop],
        startPoint: UnitPoint,
        endPoint: UnitPoint,
        curve: Curve = .smoothstep,
        samples: Int = 32
    ) {
        self.init(
            gradient: Gradient(stops: stops),
            startPoint: startPoint,
            endPoint: endPoint,
            curve: curve,
            samples: samples
        )
    }

    var body: some View {
        linearGradient
    }

    typealias Resolved = LinearGradient

    func resolve(in environment: EnvironmentValues) -> LinearGradient {
        linearGradient
    }

    var linearGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: easedStops),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    private var easedStops: [Gradient.Stop] {
        let stops = normalizedStops

        guard stops.count > 1 else {
            return stops
        }

        return (0 ... samples).map { index in
            let location = Double(index) / Double(samples)
            let easedLocation = curve.value(at: location)

            return Gradient.Stop(
                color: Self.color(at: easedLocation, in: stops),
                location: CGFloat(location)
            )
        }
    }

    private var normalizedStops: [Gradient.Stop] {
        let sortedStops = stops.sorted { $0.location < $1.location }

        switch sortedStops.count {
        case 0:
            return [
                Gradient.Stop(color: .clear, location: 0),
                Gradient.Stop(color: .clear, location: 1),
            ]
        case 1:
            return [
                Gradient.Stop(color: sortedStops[0].color, location: 0),
                Gradient.Stop(color: sortedStops[0].color, location: 1),
            ]
        default:
            return sortedStops.map {
                Gradient.Stop(color: $0.color, location: $0.location.clamped(to: 0 ... 1))
            }
        }
    }

    private static func color(at location: Double, in stops: [Gradient.Stop]) -> Color {
        let location = CGFloat(location.clamped(to: 0 ... 1))

        guard let first = stops.first else {
            return .clear
        }

        if location <= first.location {
            return first.color
        }

        for index in 0 ..< (stops.count - 1) {
            let lower = stops[index]
            let upper = stops[index + 1]

            guard location <= upper.location else {
                continue
            }

            let distance = upper.location - lower.location

            guard distance > 0 else {
                return upper.color
            }

            let amount = Double((location - lower.location) / distance)
            return blendedColor(from: lower.color, to: upper.color, amount: amount)
        }

        return stops.last?.color ?? first.color
    }

    private static func blendedColor(from lower: Color, to upper: Color, amount: Double) -> Color {
        let amount = amount.clamped(to: 0 ... 1)

        return Color(uiColor: UIColor { traits in
            let lowerColor = UIColor(lower).resolvedColor(with: traits)
            let upperColor = UIColor(upper).resolvedColor(with: traits)

            guard let lowerRGBA = EasedGradientRGBA(color: lowerColor),
                  let upperRGBA = EasedGradientRGBA(color: upperColor)
            else {
                return amount < 0.5 ? lowerColor : upperColor
            }

            return UIColor(easedGradientRGBA: lowerRGBA.blended(with: upperRGBA, amount: amount))
        })
    }
}

private struct EasedGradientRGBA {

    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    func blended(with other: Self, amount: Double) -> Self {
        let amount = CGFloat(amount.clamped(to: 0 ... 1))

        return Self(
            red: red + (other.red - red) * amount,
            green: green + (other.green - green) * amount,
            blue: blue + (other.blue - blue) * amount,
            alpha: alpha + (other.alpha - alpha) * amount
        )
    }
}

private extension EasedGradientRGBA {

    init?(color: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

private extension UIColor {

    convenience init(easedGradientRGBA rgba: EasedGradientRGBA) {
        self.init(
            red: rgba.red.clamped(to: 0 ... 1),
            green: rgba.green.clamped(to: 0 ... 1),
            blue: rgba.blue.clamped(to: 0 ... 1),
            alpha: rgba.alpha.clamped(to: 0 ... 1)
        )
    }
}
