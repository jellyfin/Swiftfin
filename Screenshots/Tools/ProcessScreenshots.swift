//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AppKit

let arguments = CommandLine.arguments.dropFirst()

guard arguments.count == 4 || arguments.count == 5 else {
    print(
        "Usage: swift Screenshots/Tools/ProcessScreenshots.swift <capture directory> <output directory> <device> <captions directory> [--raw-only]"
    )
    exit(1)
}

let captureDirectory = URL(fileURLWithPath: arguments[arguments.startIndex])
let outputDirectory = URL(fileURLWithPath: arguments[arguments.startIndex + 1])
let device = arguments[arguments.startIndex + 2]
let captionsDirectory = URL(fileURLWithPath: arguments[arguments.startIndex + 3])
let isRawOnly = arguments.contains("--raw-only")

let scriptDirectory = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let framesDirectory = scriptDirectory.appendingPathComponent("Frames")
let fontsDirectory = scriptDirectory.appendingPathComponent("Fonts")

// MARK: - Images

func loadImage(at url: URL) -> CGImage? {
    (try? Data(contentsOf: url)).flatMap { NSBitmapImageRep(data: $0)?.cgImage }
}

func write(_ image: CGImage, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?.write(to: url)
}

func makeContext(width: Int, height: Int) -> CGContext {
    CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
}

func framed(_ screenshot: CGImage) -> CGImage? {
    let size = "\(screenshot.width)x\(screenshot.height)"

    guard let frame = loadImage(at: framesDirectory.appendingPathComponent("\(size).png")) else {
        return nil
    }

    let context = makeContext(width: frame.width, height: frame.height)
    let screenshotRect = CGRect(
        x: (frame.width - screenshot.width) / 2,
        y: (frame.height - screenshot.height) / 2,
        width: screenshot.width,
        height: screenshot.height
    )

    context.saveGState()
    if let mask = loadImage(at: framesDirectory.appendingPathComponent("\(size)-mask.png")) {
        context.clip(to: screenshotRect, mask: mask)
    }
    context.draw(screenshot, in: screenshotRect)
    context.restoreGState()

    context.draw(frame, in: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))

    return context.makeImage()
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
        textTop: 0.04,
        textBottom: 0.17,
        textWidth: 0.86,
        headlineSize: 0.095,
        subtitleSize: 0.045,
        deviceTop: 0.19,
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

func font(_ file: String, size: CGFloat, weight: Int) -> NSFont {
    guard let descriptor =
        (CTFontManagerCreateFontDescriptorsFromURL(fontsDirectory.appendingPathComponent(file) as CFURL) as? [NSFontDescriptor])?.first,
        let font = NSFont(descriptor: descriptor.addingAttributes([.variation: [0x7767_6874: weight]]), size: size)
    else {
        print("Missing font \(fontsDirectory.path)/\(file)")
        exit(1)
    }

    return font
}

func captionText(_ caption: [String: String], size: CGSize, scale: CGFloat) -> NSAttributedString {
    let layout = Layout(size: size)
    let unit = min(size.width, size.height)
    let paragraphStyle = NSMutableParagraphStyle()

    paragraphStyle.alignment = .center
    paragraphStyle.paragraphSpacing = unit * layout.subtitleSize * scale * 0.5

    let text = NSMutableAttributedString(
        string: "\(caption["headline"] ?? "")\n",
        attributes: [
            .font: font("Figtree.ttf", size: unit * layout.headlineSize * scale, weight: 800),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle,
        ]
    )

    text.append(NSAttributedString(
        string: caption["subtitle"] ?? "",
        attributes: [
            .font: font("Inter.ttf", size: unit * layout.subtitleSize * scale, weight: 400),
            .foregroundColor: NSColor.white.withAlphaComponent(0.7),
            .paragraphStyle: paragraphStyle,
        ]
    ))

    return text
}

func height(of text: NSAttributedString, width: CGFloat) -> CGFloat {
    ceil(text.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin).height)
}

func fittingScale(for caption: [String: String], size: CGSize) -> CGFloat {
    let layout = Layout(size: size)
    var scale: CGFloat = 1

    while scale > 0.4,
          height(of: captionText(caption, size: size, scale: scale), width: size.width * layout.textWidth) >
          size.height * (layout.textBottom - layout.textTop)
    {
        scale *= 0.95
    }

    return scale
}

func card(caption: [String: String], raw: CGImage, framed: CGImage?, textScale: CGFloat) -> CGImage? {
    let size = CGSize(width: raw.width, height: raw.height)
    let layout = Layout(size: size)
    let unit = min(size.width, size.height)
    let context = makeContext(width: raw.width, height: raw.height)

    let background = CGGradient(
        colorsSpace: nil,
        colors: [
            CGColor(srgbRed: 0x1D / 255, green: 0x10 / 255, blue: 0x33 / 255, alpha: 1),
            CGColor(srgbRed: 0x08 / 255, green: 0x07 / 255, blue: 0x0D / 255, alpha: 1),
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(background, start: CGPoint(x: 0, y: size.height), end: .zero, options: [])

    let glows = [
        (
            CGColor(srgbRed: 0xAA / 255, green: 0x5C / 255, blue: 0xC3 / 255, alpha: 0.55),
            CGPoint(x: size.width * 0.2, y: size.height * 0.9)
        ),
        (
            CGColor(srgbRed: 0x00 / 255, green: 0xA4 / 255, blue: 0xDC / 255, alpha: 0.35),
            CGPoint(x: size.width * 0.85, y: size.height * 0.75)
        ),
    ]

    for (color, center) in glows {
        let glow = CGGradient(colorsSpace: nil, colors: [color, color.copy(alpha: 0)!] as CFArray, locations: [0, 1])!
        context.drawRadialGradient(
            glow,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: max(size.width, size.height) * 0.6,
            options: []
        )
    }

    let text = captionText(caption, size: size, scale: textScale)
    let textWidth = size.width * layout.textWidth
    let textHeight = height(of: text, width: textWidth)

    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    text.draw(
        with: CGRect(
            x: (size.width - textWidth) / 2,
            y: size.height * (1 - layout.textTop) - textHeight,
            width: textWidth,
            height: textHeight
        ),
        options: .usesLineFragmentOrigin
    )

    let device = framed ?? raw
    let deviceWidth = size.width * layout.deviceWidth
    let deviceHeight = deviceWidth * CGFloat(device.height) / CGFloat(device.width)
    let deviceRect = CGRect(
        x: (size.width - deviceWidth) / 2,
        y: size.height * (1 - layout.deviceTop) - deviceHeight,
        width: deviceWidth,
        height: deviceHeight
    )

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -unit * 0.01), blur: unit * 0.05, color: CGColor(gray: 0, alpha: 0.6))

    if framed == nil {
        let radius = deviceRect.width * 0.02
        let path = CGPath(roundedRect: deviceRect, cornerWidth: radius, cornerHeight: radius, transform: nil)

        context.addPath(path)
        context.setFillColor(.black)
        context.fillPath()

        context.setShadow(offset: .zero, blur: 0)
        context.addPath(path)
        context.clip()
    }

    context.draw(device, in: deviceRect)
    context.restoreGState()

    return context.makeImage()
}

// MARK: - Process

func collect(_ language: URL) throws -> URL {
    let languageDirectory = outputDirectory.appendingPathComponent(language.lastPathComponent)
    let rawDirectory = languageDirectory.appendingPathComponent("Raw")

    try FileManager.default.createDirectory(at: rawDirectory, withIntermediateDirectories: true)

    for screenshot in try FileManager.default.contentsOfDirectory(at: language, includingPropertiesForKeys: nil)
        where screenshot.pathExtension == "png"
    {
        let name = screenshot.lastPathComponent.replacing("\(device)-", with: "")
        try FileManager.default.copyItem(at: screenshot, to: rawDirectory.appendingPathComponent(name))
    }

    return languageDirectory
}

func process(_ languageDirectory: URL) throws {
    let screenshots = try FileManager.default
        .contentsOfDirectory(at: languageDirectory.appendingPathComponent("Raw"), includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "png" }
        .compactMap { url in
            loadImage(at: url).map { raw in
                (name: url.deletingPathExtension().lastPathComponent, raw: raw, framed: framed(raw))
            }
        }

    let captioned = screenshots.compactMap { screenshot in
        (try? Data(contentsOf: captionsDirectory.appendingPathComponent("\(screenshot.name).json")))
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) }
            .map { (screenshot: screenshot, caption: $0) }
    }

    let textScales = Dictionary(grouping: captioned) { $0.screenshot.raw.height > $0.screenshot.raw.width }
        .mapValues { group in
            group.map { fittingScale(for: $0.caption, size: CGSize(width: $0.screenshot.raw.width, height: $0.screenshot.raw.height)) }
                .min() ?? 1
        }

    for screenshot in screenshots {
        if let framed = screenshot.framed {
            try write(framed, to: languageDirectory.appendingPathComponent("Frame/\(screenshot.name).png"))
        }
    }

    for (screenshot, caption) in captioned {
        guard let image = card(
            caption: caption,
            raw: screenshot.raw,
            framed: screenshot.framed,
            textScale: textScales[screenshot.raw.height > screenshot.raw.width] ?? 1
        ) else {
            print("Unable to make card for \(screenshot.name)")
            exit(1)
        }

        try write(image, to: languageDirectory.appendingPathComponent("Card/\(screenshot.name).png"))
    }

    print("Framed \(screenshots.count { $0.framed != nil }) and made \(captioned.count) cards in \(languageDirectory.path)")
}

try? FileManager.default.removeItem(at: outputDirectory)

let languages = try FileManager.default
    .contentsOfDirectory(at: captureDirectory, includingPropertiesForKeys: [.isDirectoryKey])
    .filter(\.hasDirectoryPath)

for language in languages {
    let languageDirectory = try collect(language)

    if !isRawOnly {
        try process(languageDirectory)
    }
}
