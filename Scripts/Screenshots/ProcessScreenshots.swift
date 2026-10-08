//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Caption: Decodable {
    let headline: String
    let subtitle: String
}

let arguments = CommandLine.arguments.dropFirst()

guard arguments.count == 2 else {
    print("Usage: swift Scripts/Screenshots/ProcessScreenshots.swift <language directory> <captions directory>")
    exit(1)
}

let languageDirectory = URL(fileURLWithPath: arguments[arguments.startIndex])
let captionsDirectory = URL(fileURLWithPath: arguments[arguments.startIndex + 1])
let rawDirectory = languageDirectory.appendingPathComponent("Raw")
let framedDirectory = languageDirectory.appendingPathComponent("Framed")
let cardsDirectory = languageDirectory.appendingPathComponent("Cards")

let scriptDirectory = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let framesDirectory = scriptDirectory.appendingPathComponent("Frames")
let fontsDirectory = scriptDirectory.appendingPathComponent("Fonts")

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

// MARK: - Images

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(
        colorSpace: colorSpace,
        components: [
            CGFloat((hex >> 16) & 0xFF) / 255,
            CGFloat((hex >> 8) & 0xFF) / 255,
            CGFloat(hex & 0xFF) / 255,
            alpha,
        ]
    )!
}

func makeContext(width: Int, height: Int) -> CGContext? {
    CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
}

func loadImage(at url: URL) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

func write(_ image: CGImage, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw CocoaError(.fileWriteUnknown)
    }

    CGImageDestinationAddImage(destination, image, nil)

    guard CGImageDestinationFinalize(destination) else {
        throw CocoaError(.fileWriteUnknown)
    }
}

// MARK: - Framing

func grayscale(_ image: CGImage) -> CGImage? {
    guard let context = CGContext(
        data: nil,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue
    ) else { return nil }

    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return context.makeImage()
}

func rotated(_ image: CGImage) -> CGImage? {
    guard let context = makeContext(width: image.height, height: image.width) else { return nil }

    context.translateBy(x: CGFloat(image.height), y: 0)
    context.rotate(by: .pi / 2)
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

    return context.makeImage()
}

func frameAssets(width: Int, height: Int) -> (frame: CGImage, mask: CGImage?)? {
    func load(_ size: String, _ kind: String) -> CGImage? {
        loadImage(at: framesDirectory.appendingPathComponent("\(size)-\(kind).png"))
    }

    if let frame = load("\(width)x\(height)", "frame") {
        return (frame, load("\(width)x\(height)", "mask"))
    }

    if let frame = load("\(height)x\(width)", "frame").flatMap(rotated) {
        return (frame, load("\(height)x\(width)", "mask").flatMap(rotated))
    }

    return nil
}

func framed(_ screenshot: CGImage) -> CGImage? {
    guard let assets = frameAssets(width: screenshot.width, height: screenshot.height),
          let context = makeContext(width: assets.frame.width, height: assets.frame.height)
    else { return nil }

    let screenshotRect = CGRect(
        x: (assets.frame.width - screenshot.width) / 2,
        y: (assets.frame.height - screenshot.height) / 2,
        width: screenshot.width,
        height: screenshot.height
    )

    context.saveGState()
    if let mask = assets.mask.flatMap(grayscale) {
        context.clip(to: screenshotRect, mask: mask)
    }
    context.draw(screenshot, in: screenshotRect)
    context.restoreGState()

    context.draw(assets.frame, in: CGRect(x: 0, y: 0, width: assets.frame.width, height: assets.frame.height))

    return context.makeImage()
}

// MARK: - Text

func font(_ file: String, size: CGFloat, weight: Int) -> CTFont {
    guard let descriptor =
        (CTFontManagerCreateFontDescriptorsFromURL(fontsDirectory.appendingPathComponent(file) as CFURL) as? [CTFontDescriptor])?.first
    else {
        print("Missing font \(fontsDirectory.path)/\(file)")
        exit(1)
    }

    let weightAxis = 0x7767_6874
    let weighted = CTFontDescriptorCreateCopyWithAttributes(
        descriptor,
        [kCTFontVariationAttribute: [weightAxis: weight]] as CFDictionary
    )

    return CTFontCreateWithFontDescriptor(weighted, size, nil)
}

func attributedText(_ text: String, font: CTFont, color: CGColor) -> NSAttributedString {
    var alignment = CTTextAlignment.center
    let paragraphStyle = withUnsafeBytes(of: &alignment) { pointer in
        var setting = CTParagraphStyleSetting(
            spec: .alignment,
            valueSize: MemoryLayout<CTTextAlignment>.size,
            value: pointer.baseAddress!
        )
        return CTParagraphStyleCreate(&setting, 1)
    }

    return NSAttributedString(
        string: text,
        attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
            NSAttributedString.Key(kCTParagraphStyleAttributeName as String): paragraphStyle,
        ]
    )
}

func textHeight(_ text: NSAttributedString, width: CGFloat) -> CGFloat {
    let framesetter = CTFramesetterCreateWithAttributedString(text)
    let size = CTFramesetterSuggestFrameSizeWithConstraints(
        framesetter,
        CFRange(location: 0, length: 0),
        nil,
        CGSize(width: width, height: .greatestFiniteMagnitude),
        nil
    )

    return ceil(size.height)
}

func drawText(_ text: NSAttributedString, in context: CGContext, rect: CGRect) {
    let framesetter = CTFramesetterCreateWithAttributedString(text)
    let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), CGPath(rect: rect, transform: nil), nil)
    CTFrameDraw(frame, context)
}

// MARK: - Cards

struct Layout {

    let textTop: CGFloat
    let textBottom: CGFloat
    let textWidth: CGFloat
    let headlineSize: CGFloat
    let subtitleSize: CGFloat
    let deviceTop: CGFloat
    let deviceWidth: CGFloat

    static let portrait = Layout(
        textTop: 0.05,
        textBottom: 0.2,
        textWidth: 0.86,
        headlineSize: 0.095,
        subtitleSize: 0.045,
        deviceTop: 0.22,
        deviceWidth: 0.92
    )

    static let landscape = Layout(
        textTop: 0.06,
        textBottom: 0.24,
        textWidth: 0.7,
        headlineSize: 0.08,
        subtitleSize: 0.036,
        deviceTop: 0.27,
        deviceWidth: 0.8
    )
}

extension Layout {

    init(size: CGSize) {
        self = size.height > size.width ? .portrait : .landscape
    }
}

struct CardText {

    let headline: NSAttributedString
    let subtitle: NSAttributedString
    let headlineHeight: CGFloat
    let subtitleHeight: CGFloat
    let spacing: CGFloat

    var height: CGFloat {
        headlineHeight + spacing + subtitleHeight
    }

    init(caption: Caption, size: CGSize, scale: CGFloat) {
        let layout = Layout(size: size)
        let unit = min(size.width, size.height)
        let width = size.width * layout.textWidth

        headline = attributedText(
            caption.headline,
            font: font("Figtree.ttf", size: unit * layout.headlineSize * scale, weight: 800),
            color: color(0xFFFFFF)
        )
        subtitle = attributedText(
            caption.subtitle,
            font: font("Inter.ttf", size: unit * layout.subtitleSize * scale, weight: 400),
            color: color(0xFFFFFF, alpha: 0.7)
        )
        headlineHeight = textHeight(headline, width: width)
        subtitleHeight = textHeight(subtitle, width: width)
        spacing = unit * layout.subtitleSize * scale * 0.5
    }

    static func fittingScale(for caption: Caption, size: CGSize) -> CGFloat {
        let layout = Layout(size: size)
        let boxHeight = size.height * (layout.textBottom - layout.textTop)
        var scale: CGFloat = 1

        while scale > 0.4, CardText(caption: caption, size: size, scale: scale).height > boxHeight {
            scale *= 0.95
        }

        return scale
    }
}

func drawBackground(in context: CGContext, size: CGSize) {
    let base = CGGradient(
        colorsSpace: colorSpace,
        colors: [color(0x1D1033), color(0x08070D)] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(base, start: CGPoint(x: 0, y: size.height), end: .zero, options: [])

    let glows: [(UInt32, CGFloat, CGPoint)] = [
        (0xAA5CC3, 0.55, CGPoint(x: size.width * 0.2, y: size.height * 0.9)),
        (0x00A4DC, 0.35, CGPoint(x: size.width * 0.85, y: size.height * 0.75)),
    ]

    for (hex, alpha, center) in glows {
        let glow = CGGradient(
            colorsSpace: colorSpace,
            colors: [color(hex, alpha: alpha), color(hex, alpha: 0)] as CFArray,
            locations: [0, 1]
        )!
        context.drawRadialGradient(
            glow,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: max(size.width, size.height) * 0.6,
            options: []
        )
    }
}

func card(caption: Caption, device: CGImage, isFramed: Bool, size: CGSize, textScale: CGFloat) -> CGImage? {
    guard let context = makeContext(width: Int(size.width), height: Int(size.height)) else { return nil }

    drawBackground(in: context, size: size)

    let layout = Layout(size: size)
    let unit = min(size.width, size.height)
    let textWidth = size.width * layout.textWidth
    let textX = (size.width - textWidth) / 2
    let text = CardText(caption: caption, size: size, scale: textScale)

    let headlineTop = size.height * (1 - layout.textTop)
    drawText(
        text.headline,
        in: context,
        rect: CGRect(x: textX, y: headlineTop - text.headlineHeight, width: textWidth, height: text.headlineHeight)
    )
    drawText(
        text.subtitle,
        in: context,
        rect: CGRect(
            x: textX,
            y: headlineTop - text.headlineHeight - text.spacing - text.subtitleHeight,
            width: textWidth,
            height: text.subtitleHeight
        )
    )

    let deviceWidth = size.width * layout.deviceWidth
    let deviceHeight = deviceWidth * CGFloat(device.height) / CGFloat(device.width)
    let deviceRect = CGRect(
        x: (size.width - deviceWidth) / 2,
        y: size.height * (1 - layout.deviceTop) - deviceHeight,
        width: deviceWidth,
        height: deviceHeight
    )

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -unit * 0.01), blur: unit * 0.05, color: color(0x000000, alpha: 0.6))

    if isFramed {
        context.draw(device, in: deviceRect)
    } else {
        let radius = deviceRect.width * 0.02
        let path = CGPath(roundedRect: deviceRect, cornerWidth: radius, cornerHeight: radius, transform: nil)

        context.addPath(path)
        context.setFillColor(color(0x000000))
        context.fillPath()

        context.setShadow(offset: .zero, blur: 0)
        context.addPath(path)
        context.clip()
        context.draw(device, in: deviceRect)
    }

    context.restoreGState()

    return context.makeImage()
}

// MARK: - Process

struct Screenshot {

    let name: String
    let raw: CGImage
    let framed: CGImage?
    let caption: Caption?

    var size: CGSize {
        CGSize(width: raw.width, height: raw.height)
    }

    var isPortrait: Bool {
        size.height > size.width
    }
}

let screenshots = ((try? FileManager.default.contentsOfDirectory(at: rawDirectory, includingPropertiesForKeys: nil)) ?? [])
    .filter { $0.pathExtension == "png" }
    .compactMap { url -> Screenshot? in
        guard let raw = loadImage(at: url) else { return nil }

        let name = url.deletingPathExtension().lastPathComponent
        let caption = (try? Data(contentsOf: captionsDirectory.appendingPathComponent("\(name).json")))
            .flatMap { try? JSONDecoder().decode(Caption.self, from: $0) }

        return Screenshot(name: name, raw: raw, framed: framed(raw), caption: caption)
    }

try? FileManager.default.removeItem(at: framedDirectory)
try? FileManager.default.removeItem(at: cardsDirectory)

for screenshot in screenshots {
    if let framed = screenshot.framed {
        try write(framed, to: framedDirectory.appendingPathComponent("\(screenshot.name).png"))
    }
}

let captioned = screenshots.filter { $0.caption != nil }
let textScales = Dictionary(grouping: captioned, by: \.isPortrait)
    .mapValues { group in
        group.map { CardText.fittingScale(for: $0.caption!, size: $0.size) }.min() ?? 1
    }

for screenshot in captioned {
    guard let image = card(
        caption: screenshot.caption!,
        device: screenshot.framed ?? screenshot.raw,
        isFramed: screenshot.framed != nil,
        size: screenshot.size,
        textScale: textScales[screenshot.isPortrait] ?? 1
    ) else {
        print("Unable to make card for \(screenshot.name)")
        exit(1)
    }

    try write(image, to: cardsDirectory.appendingPathComponent("\(screenshot.name).png"))
}

print("Framed \(screenshots.count { $0.framed != nil }) and made \(captioned.count) cards in \(languageDirectory.path)")
