//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

extension UIImage {

    /// Interesting color based on median-cut
    func interestingColor() -> Color? {
        guard let sample = quantizedColorSample() else {
            return nil
        }

        return Color(
            uiColor: UIColor(
                red: sample.red / 255,
                green: sample.green / 255,
                blue: sample.blue / 255,
                alpha: 1
            )
        )
    }

    private func quantizedColorSample() -> ColorSample? {
        guard let cgImage else { return nil }

        let maximumSampleDimension = 48
        let aspectRatio = Double(cgImage.width) / Double(cgImage.height)
        let sampleWidth: Int
        let sampleHeight: Int

        if cgImage.width >= cgImage.height {
            sampleWidth = maximumSampleDimension
            sampleHeight = max(1, Int(round(Double(maximumSampleDimension) / aspectRatio)))
        } else {
            sampleWidth = max(1, Int(round(Double(maximumSampleDimension) * aspectRatio)))
            sampleHeight = maximumSampleDimension
        }

        let bytesPerPixel = 4
        let bytesPerRow = sampleWidth * bytesPerPixel
        var pixels: [UInt8] = .init(repeating: 0, count: sampleHeight * bytesPerRow)
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue |
            CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(
            data: &pixels,
            width: sampleWidth,
            height: sampleHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight))

        var histogram: [Int: ColorAccumulator] = [:]
        histogram.reserveCapacity(sampleWidth * sampleHeight)

        for offset in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            let red = pixels[offset]
            let green = pixels[offset + 1]
            let blue = pixels[offset + 2]
            let alpha = pixels[offset + 3]

            guard alpha > 127 else { continue }

            let key = colorBucketKey(red: red, green: green, blue: blue)
            histogram[key, default: ColorAccumulator()]
                .append(red: red, green: green, blue: blue)
        }

        return medianCutColor(from: histogram.values.map(\.sample))
    }

    private func colorBucketKey(
        red: UInt8,
        green: UInt8,
        blue: UInt8
    ) -> Int {
        (Int(red) >> 3) << 10 |
            (Int(green) >> 3) << 5 |
            (Int(blue) >> 3)
    }
}

private struct ColorAccumulator {

    private var redTotal = 0
    private var greenTotal = 0
    private var blueTotal = 0
    private var count = 0

    var sample: ColorSample {
        let divisor = CGFloat(max(count, 1))

        return ColorSample(
            red: CGFloat(redTotal) / divisor,
            green: CGFloat(greenTotal) / divisor,
            blue: CGFloat(blueTotal) / divisor,
            count: count
        )
    }

    mutating func append(
        red: UInt8,
        green: UInt8,
        blue: UInt8
    ) {
        redTotal += Int(red)
        greenTotal += Int(green)
        blueTotal += Int(blue)
        count += 1
    }
}

private struct ColorSample {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var count = 1

    var interestScore: Double {
        interestScore(totalCount: count)
    }

    func interestScore(totalCount: Int) -> Double {
        let red = Double(red)
        let green = Double(green)
        let blue = Double(blue)
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let saturation = maximum.isZero ? 0 : (maximum - minimum) / maximum
        let luminance = ((0.2126 * red) + (0.7152 * green) + (0.0722 * blue)) / 255
        let targetLuminance = 0.42
        let luminanceScore = 1 - min(1, abs(luminance - targetLuminance) / targetLuminance)

        return log(Double(totalCount) + 1) * (0.7 + saturation) * (0.55 + luminanceScore)
    }
}

private struct ColorBox {
    var samples: [ColorSample]

    var canSplit: Bool {
        samples.count > 1
    }

    var totalCount: Int {
        samples.reduce(0) { $0 + $1.count }
    }

    var longestChannel: WritableKeyPath<ColorSample, CGFloat> {
        let redRange = range(\.red)
        let greenRange = range(\.green)
        let blueRange = range(\.blue)

        if redRange >= greenRange, redRange >= blueRange {
            return \.red
        } else if greenRange >= blueRange {
            return \.green
        } else {
            return \.blue
        }
    }

    var volume: CGFloat {
        let redRange = max(range(\.red), 1)
        let greenRange = max(range(\.green), 1)
        let blueRange = max(range(\.blue), 1)

        return redRange * greenRange * blueRange
    }

    var splitPriority: Double {
        Double(volume) * log(Double(totalCount) + 1)
    }

    var average: ColorSample {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var count = 0

        for sample in samples {
            let sampleCount = CGFloat(sample.count)
            red += sample.red * sampleCount
            green += sample.green * sampleCount
            blue += sample.blue * sampleCount
            count += sample.count
        }

        let divisor = CGFloat(max(count, 1))

        return ColorSample(
            red: red / divisor,
            green: green / divisor,
            blue: blue / divisor,
            count: count
        )
    }

    func split() -> (ColorBox, ColorBox)? {
        guard canSplit else { return nil }

        let channel = longestChannel
        let sortedSamples = samples.sorted { $0[keyPath: channel] < $1[keyPath: channel] }
        let midpoint = max(totalCount / 2, 1)
        var splitIndex = sortedSamples.startIndex
        var count = 0

        for index in sortedSamples.indices {
            count += sortedSamples[index].count

            if count >= midpoint {
                splitIndex = sortedSamples.index(after: index)
                break
            }
        }

        guard splitIndex > sortedSamples.startIndex,
              splitIndex < sortedSamples.endIndex
        else { return nil }

        return (
            ColorBox(samples: Array(sortedSamples[..<splitIndex])),
            ColorBox(samples: Array(sortedSamples[splitIndex...]))
        )
    }

    private func range(_ keyPath: KeyPath<ColorSample, CGFloat>) -> CGFloat {
        guard var minimum = samples.first?[keyPath: keyPath] else {
            return 0
        }

        var maximum = minimum

        for sample in samples.dropFirst() {
            let value = sample[keyPath: keyPath]
            minimum = min(minimum, value)
            maximum = max(maximum, value)
        }

        return maximum - minimum
    }
}

private func medianCutColor(
    from samples: [ColorSample],
    paletteSize: Int = 6
) -> ColorSample? {
    guard !samples.isEmpty else { return nil }

    var boxes = [ColorBox(samples: samples)]

    while boxes.count < paletteSize {
        guard let splitIndex = splittableBoxIndex(in: boxes),
              let splitBoxes = boxes[splitIndex].split()
        else {
            break
        }

        boxes.remove(at: splitIndex)
        boxes.append(splitBoxes.0)
        boxes.append(splitBoxes.1)
    }

    return boxes
        .map(\.average)
        .max(by: { $0.interestScore < $1.interestScore })
}

private func splittableBoxIndex(in boxes: [ColorBox]) -> Int? {
    var selectedIndex: Int?
    var selectedPriority = 0.0

    for index in boxes.indices where boxes[index].canSplit {
        if selectedIndex == nil || boxes[index].splitPriority > selectedPriority {
            selectedIndex = index
            selectedPriority = boxes[index].splitPriority
        }
    }

    return selectedIndex
}
