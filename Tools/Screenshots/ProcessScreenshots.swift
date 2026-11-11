//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AppKit
import UniformTypeIdentifiers

let files = FileManager.default
let toolsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let repository = toolsDirectory.deletingLastPathComponent().deletingLastPathComponent()

struct Profile: Decodable {

    let name: String
    let device: String
    let sizes: Set<[Int]>

    var platformName: String {
        name.hasPrefix("iPhone") ? "iOS" : name
    }
}

struct ScreenshotError: LocalizedError {

    let message: String

    var errorDescription: String? {
        message
    }
}

func contents(of directory: URL) throws -> [URL] {
    try files.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
}

func resolvedPath(_ url: URL) -> [String] {
    var ancestor = url.standardizedFileURL
    var missingComponents: [String] = []

    // Foundation only resolves symlinks when the entire path exists.
    while !files.fileExists(atPath: ancestor.path) {
        missingComponents.append(ancestor.lastPathComponent)
        ancestor.deleteLastPathComponent()
    }

    return ancestor.resolvingSymlinksInPath().pathComponents + missingComponents.reversed()
}

func languages(in directory: URL) throws -> [URL] {
    let languages = try contents(of: directory).filter(\.hasDirectoryPath)

    guard !languages.isEmpty else { throw ScreenshotError(message: "No localizations in \(directory.path)") }

    return languages
}

/// The demo scene is lit. Sample the picture on either side of the transport controls.
func hasPlaybackPicture(_ image: CGImage) -> Bool {
    let width = 16
    let height = 10

    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue
    ), let data = context.data else { return false }

    context.interpolationQuality = .medium
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    let pixels = data.assumingMemoryBound(to: UInt8.self)

    return (3 ... 6).contains { row in
        [3, 4, 11, 12].contains { column in pixels[row * width + column] > 12 }
    }
}

func validatedSizes(_ profile: Profile, in folder: URL, isRaw: Bool) throws -> [String: [Int]] {
    let files = try contents(of: folder)

    guard (1 ... 10).contains(files.count) else { throw ScreenshotError(message: "Expected 1–10 images in \(folder.path)") }

    var foundSizes = Set<[Int]>()
    var sceneSizes: [String: [Int]] = [:]

    for file in files {
        guard file.pathExtension == "png",
              let source = CGImageSourceCreateWithURL(file as CFURL, nil),
              CGImageSourceGetType(source) as String? == UTType.png.identifier,
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              [.none, .noneSkipFirst, .noneSkipLast].contains(image.alphaInfo)
        else { throw ScreenshotError(message: "Expected an opaque PNG in \(file.path)") }

        let size = [image.width, image.height].sorted()

        guard profile.sizes.contains(size), profile.name != "tvOS" || image.width > image.height else {
            throw ScreenshotError(message: "Unsupported \(profile.name) size \(image.width)×\(image.height) in \(file.path)")
        }

        if isRaw, file.lastPathComponent == "Playback.png", !hasPlaybackPicture(image) {
            throw ScreenshotError(message: "Playback capture has no visible video frame in \(file.path)")
        }

        foundSizes.insert(size)
        sceneSizes[file.lastPathComponent] = [image.width, image.height]
    }

    if profile.name == "iPhoneDuo", foundSizes != profile.sizes {
        throw ScreenshotError(message: "The Duo gallery needs captures from both displays in \(folder.path)")
    }

    print("Validated \(files.count) screenshots in \(folder.path)")
    return sceneSizes
}

func validate(_ profile: Profile, raw: URL, gallery: URL?) throws {
    let localizations = try languages(in: raw)
    let frames = try gallery == nil ? [:] : loadFrames(for: profile)

    if let gallery, try Set(languages(in: gallery).map(\.lastPathComponent)) != Set(localizations.map(\.lastPathComponent)) {
        throw ScreenshotError(message: "Raw and Card localizations differ in \(gallery.path)")
    }

    for language in localizations {
        let rawSizes = try validatedSizes(profile, in: language, isRaw: true)

        if let gallery {
            let cards = gallery.appendingPathComponent("\(language.lastPathComponent)/Card")
            guard try validatedSizes(profile, in: cards, isRaw: false) == rawSizes else {
                throw ScreenshotError(message: "Raw and Card scenes or dimensions differ in \(cards.path)")
            }

            let framed = gallery.appendingPathComponent("\(language.lastPathComponent)/Frame")
            let images = try contents(of: framed)

            guard Set(images.map(\.lastPathComponent)) == Set(rawSizes.keys) else {
                throw ScreenshotError(message: "Every card needs a matching framed screenshot in \(framed.path)")
            }

            for file in images {
                guard let size = rawSizes[file.lastPathComponent],
                      let frame = frames[size.sorted()],
                      let source = CGImageSourceCreateWithURL(file as CFURL, nil),
                      CGImageSourceGetType(source) as String? == UTType.png.identifier,
                      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
                      [.first, .last, .premultipliedFirst, .premultipliedLast].contains(image.alphaInfo),
                      [image.width, image.height] == frame.outputSize(for: size)
                else { throw ScreenshotError(message: "Invalid framed screenshot in \(file.path)") }
            }

            print("Validated \(images.count) device frames in \(framed.path)")
        }
    }
}

// MARK: - Images

func loadImage(at url: URL) -> CGImage? {
    (try? Data(contentsOf: url)).flatMap { NSBitmapImageRep(data: $0)?.cgImage }
}

func write(_ image: CGImage, to url: URL) throws {
    try files.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

    guard let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
        throw ScreenshotError(message: "Unable to encode \(url.lastPathComponent)")
    }

    try data.write(to: url)
}

func makeContext(width: Int, height: Int, opaque: Bool = false) -> CGContext {
    CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: (opaque ? CGImageAlphaInfo.noneSkipLast : .premultipliedLast).rawValue
    )!
}

func rotated(_ image: CGImage, by angle: CGFloat) -> CGImage? {
    let context = makeContext(width: image.height, height: image.width)

    context.translateBy(x: CGFloat(image.height) / 2, y: CGFloat(image.width) / 2)
    context.rotate(by: angle)
    context.draw(image, in: CGRect(
        x: -CGFloat(image.width) / 2,
        y: -CGFloat(image.height) / 2,
        width: CGFloat(image.width),
        height: CGFloat(image.height)
    ))

    return context.makeImage()
}

struct DeviceFrame {

    private struct Screen: Decodable {

        let x: Int
        let y: Int
        let width: Int
        let height: Int
    }

    let frame: CGImage
    let mask: CGImage
    let screen: CGRect

    init(profile: Profile, size: [Int]) throws {
        let dimensions = size.sorted().map(String.init).joined(separator: "x")
        let directory = toolsDirectory.appendingPathComponent("Frames/\(profile.name)/\(profile.device)/\(dimensions)")

        guard let image = loadImage(at: directory.appendingPathComponent("Frame.png")) else {
            throw ScreenshotError(message: "Missing or unreadable device frame in \(directory.path)")
        }

        let layout = try JSONDecoder().decode(Screen.self, from: Data(contentsOf: directory.appendingPathComponent("Screen.json")))
        let rect = CGRect(x: layout.x, y: layout.y, width: layout.width, height: layout.height)

        guard [layout.width, layout.height].sorted() == size.sorted(),
              CGRect(x: 0, y: 0, width: image.width, height: image.height).contains(rect),
              image.width > layout.width,
              image.height > layout.height
        else { throw ScreenshotError(message: "Invalid screen bounds in \(directory.path)") }

        let maskURL = directory.appendingPathComponent("Mask.png")
        guard let mask = loadImage(at: maskURL), mask.width == layout.width, mask.height == layout.height else {
            throw ScreenshotError(message: "Missing, unreadable or incorrectly sized mask in \(directory.path)")
        }

        frame = image
        self.mask = mask
        screen = rect
    }

    func outputSize(for size: [Int]) -> [Int] {
        let isRotated = (screen.height > screen.width) != (size[1] > size[0])
        return isRotated ? [frame.height, frame.width] : [frame.width, frame.height]
    }

    func apply(to screenshot: CGImage) throws -> CGImage {
        let isRotated = (screen.height > screen.width) != (screenshot.height > screenshot.width)

        guard let screenshot = isRotated ? rotated(screenshot, by: -.pi / 2) : screenshot,
              screenshot.width == Int(screen.width),
              screenshot.height == Int(screen.height)
        else { throw ScreenshotError(message: "Screenshot dimensions do not match the device frame") }

        let context = makeContext(width: frame.width, height: frame.height)

        context.saveGState()

        context.clip(to: screen, mask: mask)
        context.draw(screenshot, in: screen)
        context.restoreGState()
        context.draw(frame, in: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))

        guard let image = context.makeImage().flatMap({ isRotated ? rotated($0, by: .pi / 2) : $0 }) else {
            throw ScreenshotError(message: "Unable to render the device frame")
        }

        return image
    }
}

func loadFrames(for profile: Profile) throws -> [[Int]: DeviceFrame] {
    try Dictionary(uniqueKeysWithValues: profile.sizes.map { size in
        try (size, DeviceFrame(profile: profile, size: size))
    })
}

// MARK: - Cards

struct Caption: Decodable {

    let headline: String
    let subtitle: String
}

struct Captions {

    private let scenes: [String: Caption]

    init() throws {
        let file = toolsDirectory.appendingPathComponent("Captions.json")

        scenes = try JSONDecoder().decode([String: Caption].self, from: Data(contentsOf: file))
    }

    func caption(for scene: String, platform: String) throws -> Caption {
        guard let caption = scenes[scene], !caption.headline.isEmpty, !caption.subtitle.isEmpty else {
            throw ScreenshotError(message: "Missing caption for \(scene) in Captions.json")
        }

        return Caption(
            headline: caption.headline,
            subtitle: caption.subtitle.replacing("{platform}", with: platform)
        )
    }
}

struct Layout {

    let textWidth: CGFloat
    let textTop: CGFloat
    let textHeight: CGFloat
    let headlineSize: CGFloat
    let subtitleSize: CGFloat
    let deviceWidth: CGFloat
    let deviceTop: CGFloat
    let deviceHeight: CGFloat

    init(size: CGSize) {
        let portrait = size.height > size.width
        let unit = min(size.width, size.height)
        let textBand: Range<CGFloat> = portrait ? 0.04 ..< 0.17 : 0.06 ..< 0.24
        let deviceBand: Range<CGFloat> = portrait ? 0.19 ..< 0.97 : 0.27 ..< 0.96

        textWidth = size.width * (portrait ? 0.86 : 0.7)
        textTop = size.height * (1 - textBand.lowerBound)
        textHeight = size.height * (textBand.upperBound - textBand.lowerBound)
        headlineSize = unit * (portrait ? 0.095 : 0.08)
        subtitleSize = unit * (portrait ? 0.045 : 0.036)
        deviceWidth = size.width * (portrait ? 0.92 : 0.8)
        deviceTop = size.height * (1 - deviceBand.lowerBound)
        deviceHeight = size.height * (deviceBand.upperBound - deviceBand.lowerBound)
    }
}

func font(_ file: String, size: CGFloat, weight: Int) throws -> NSFont {
    let url = toolsDirectory.appendingPathComponent("Fonts/\(file)")

    guard let descriptor =
        (CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [NSFontDescriptor])?.first,
        let font = NSFont(descriptor: descriptor.addingAttributes([.variation: [0x7767_6874: weight]]), size: size)
    else {
        throw ScreenshotError(message: "Missing font \(url.path)")
    }

    return font
}

func captionText(_ caption: Caption, layout: Layout, scale: CGFloat) throws -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()

    paragraphStyle.alignment = .center
    paragraphStyle.paragraphSpacing = layout.subtitleSize * scale * 0.5

    let text = try NSMutableAttributedString(
        string: "\(caption.headline)\n",
        attributes: [
            .font: font("Figtree.ttf", size: layout.headlineSize * scale, weight: 800),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle,
        ]
    )

    try text.append(NSAttributedString(
        string: caption.subtitle,
        attributes: [
            .font: font("Inter.ttf", size: layout.subtitleSize * scale, weight: 400),
            .foregroundColor: NSColor.white.withAlphaComponent(0.7),
            .paragraphStyle: paragraphStyle,
        ]
    ))

    return text
}

func height(of text: NSAttributedString, width: CGFloat) -> CGFloat {
    ceil(text.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin).height)
}

func fittingScale(for caption: Caption, size: CGSize) throws -> CGFloat {
    let layout = Layout(size: size)
    var scale: CGFloat = 1

    while scale > 0.4,
          try height(of: captionText(caption, layout: layout, scale: scale), width: layout.textWidth) > layout.textHeight {
        scale *= 0.95
    }

    return scale
}

func card(caption: Caption, raw: CGImage, framed: CGImage, textScale: CGFloat) throws -> CGImage? {
    let size = CGSize(width: raw.width, height: raw.height)
    let layout = Layout(size: size)
    let unit = min(size.width, size.height)
    let context = makeContext(width: raw.width, height: raw.height, opaque: true)

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

    let text = try captionText(caption, layout: layout, scale: textScale)
    let textWidth = layout.textWidth
    let textHeight = height(of: text, width: textWidth)

    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

    text.draw(
        with: CGRect(
            x: (size.width - textWidth) / 2,
            y: layout.textTop - textHeight,
            width: textWidth,
            height: textHeight
        ),
        options: .usesLineFragmentOrigin
    )

    let device = framed
    let deviceAspectRatio = CGFloat(device.width) / CGFloat(device.height)
    let deviceHeight = min(layout.deviceWidth / deviceAspectRatio, layout.deviceHeight)
    let deviceWidth = deviceHeight * deviceAspectRatio

    let deviceRect = CGRect(
        x: (size.width - deviceWidth) / 2,
        y: layout.deviceTop - deviceHeight,
        width: deviceWidth,
        height: deviceHeight
    )

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -unit * 0.01), blur: unit * 0.05, color: CGColor(gray: 0, alpha: 0.6))

    context.draw(device, in: deviceRect)
    context.restoreGState()

    return context.makeImage()
}

// MARK: - Process

/// App Store Connect requires opaque screenshots. PNGs without alpha can be copied byte for byte.
func storeRaw(_ source: URL, at target: URL) throws {
    guard !files.fileExists(atPath: target.path) else { throw ScreenshotError(message: "Duplicate capture \(target.lastPathComponent)") }
    guard let image = loadImage(at: source) else { throw ScreenshotError(message: "Unreadable capture \(source.path)") }

    if [.none, .noneSkipFirst, .noneSkipLast].contains(image.alphaInfo) {
        try files.copyItem(at: source, to: target)
        return
    }

    let context = makeContext(width: image.width, height: image.height, opaque: true)
    let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)

    context.setFillColor(CGColor(gray: 0, alpha: 1))
    context.fill(rect)
    context.draw(image, in: rect)

    guard let opaque = context.makeImage() else { throw ScreenshotError(message: "Unable to flatten \(source.path)") }

    try write(opaque, to: target)
}

func exportRaw(_ language: URL, to output: URL) throws {
    try files.createDirectory(at: output, withIntermediateDirectories: true)

    // Snapshot prefixes scene names with the simulator name.
    for source in try contents(of: language) where source.pathExtension == "png" {
        let stem = source.deletingPathExtension().lastPathComponent
        let name = stem.components(separatedBy: "-").last ?? stem
        try storeRaw(source, at: output.appendingPathComponent("\(name).png"))
    }
}

func exportGallery(_ language: URL, to output: URL, profile: Profile, frames: [[Int]: DeviceFrame]) throws {
    let captions = try Captions()
    var scenes: [(name: String, raw: CGImage, caption: Caption)] = []

    for source in try contents(of: language) where source.pathExtension == "png" {
        guard let raw = loadImage(at: source) else { throw ScreenshotError(message: "Unreadable capture \(source.path)") }

        let name = source.deletingPathExtension().lastPathComponent
        try scenes.append((name, raw, captions.caption(for: name, platform: profile.platformName)))
    }

    // A shared scale keeps caption sizes consistent across cards in the same orientation.
    let groups = Dictionary(grouping: scenes) { $0.raw.height > $0.raw.width }

    for group in groups.values {
        let scale = try group.map { try fittingScale(for: $0.caption, size: CGSize(width: $0.raw.width, height: $0.raw.height)) }.min() ?? 1

        for scene in group {
            guard let frame = frames[[scene.raw.width, scene.raw.height].sorted()] else {
                throw ScreenshotError(message: "No device frame for \(scene.name) at \(scene.raw.width)×\(scene.raw.height)")
            }

            let device = try frame.apply(to: scene.raw)
            try write(device, to: output.appendingPathComponent("Frame/\(scene.name).png"))

            guard let image = try card(caption: scene.caption, raw: scene.raw, framed: device, textScale: scale) else {
                throw ScreenshotError(message: "Unable to make card for \(scene.name)")
            }

            try write(image, to: output.appendingPathComponent("Card/\(scene.name).png"))
        }
    }
}

func compress(_ directory: URL) throws {
    let process = Process()

    // Standard lossless compression. Sequential compression limits peak memory use.
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["oxipng", "-o", "2", "--sequential", "-r", directory.path]

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw ScreenshotError(message: "oxipng failed to compress \(directory.path). Install it with 'brew install oxipng'.")
    }
}

func publish(_ profile: Profile, from capture: URL, to destination: URL, rawOnly: Bool) throws {
    let inputPath = resolvedPath(capture)
    let outputPath = resolvedPath(destination)
    let documentation = repository.appendingPathComponent("Documentation").standardizedFileURL
    if destination.standardizedFileURL.pathComponents.starts(with: documentation.pathComponents)
        || outputPath.starts(with: resolvedPath(documentation)) {
        throw ScreenshotError(message: "Store screenshots outside Documentation, under Tools/Screenshots.")
    }

    if inputPath.starts(with: outputPath) || outputPath.starts(with: inputPath) {
        throw ScreenshotError(message: "Choose separate input and output directories.")
    }

    let staging = destination.deletingLastPathComponent().appendingPathComponent(".screenshots-\(UUID().uuidString)")

    defer { try? files.removeItem(at: staging) }

    let frames = try rawOnly ? [:] : loadFrames(for: profile)

    for language in try languages(in: capture) {
        let output = staging.appendingPathComponent(language.lastPathComponent)

        if rawOnly {
            try exportRaw(language, to: output)
        } else {
            try exportGallery(language, to: output, profile: profile, frames: frames)
        }
    }

    try compress(staging)
    try validate(profile, raw: rawOnly ? staging : capture, gallery: rawOnly ? nil : staging)

    if files.fileExists(atPath: destination.path) {
        _ = try files.replaceItemAt(destination, withItemAt: staging)
    } else {
        try files.moveItem(at: staging, to: destination)
    }
}

func run() throws {
    struct Runtime: Decodable {

        let profiles: [Profile]
    }

    let profilesFile = toolsDirectory.appendingPathComponent("Profiles.json")
    let profiles = try JSONDecoder().decode([Runtime].self, from: Data(contentsOf: profilesFile)).flatMap(\.profiles)
    let raw = toolsDirectory.appendingPathComponent("Raw")
    let galleries = toolsDirectory.appendingPathComponent("Output")
    var arguments = Array(CommandLine.arguments.dropFirst())
    let rawOnly = arguments.last == "--raw-only"

    if rawOnly {
        arguments.removeLast()
    }

    if arguments.first == "--validate" {
        arguments.removeFirst()

        if arguments.isEmpty {
            for profile in profiles {
                try validate(
                    profile,
                    raw: raw.appendingPathComponent(profile.name),
                    gallery: rawOnly ? nil : galleries.appendingPathComponent(profile.name)
                )
            }

            return
        }

        if arguments.count == 2, let profile = profiles.first(where: { $0.name == arguments[0] }) {
            let output = URL(fileURLWithPath: arguments[1])
            try validate(profile, raw: rawOnly ? output : raw.appendingPathComponent(profile.name), gallery: rawOnly ? nil : output)
            return
        }
    } else if arguments.count == 3, let profile = profiles.first(where: { $0.name == arguments[0] }) {
        try publish(
            profile,
            from: URL(fileURLWithPath: arguments[1]),
            to: URL(fileURLWithPath: arguments[2]),
            rawOnly: rawOnly
        )

        return
    }

    throw ScreenshotError(message: """
    Usage: ProcessScreenshots.swift <profile> <capture directory> <raw directory> --raw-only
           ProcessScreenshots.swift <profile> <raw directory> <gallery directory>
           ProcessScreenshots.swift --validate [<profile> <output directory>] [--raw-only]
    Profiles: \(profiles.map(\.name).joined(separator: ", "))
    """)
}

do {
    try run()
} catch {
    print(error.localizedDescription)
    exit(1)
}
