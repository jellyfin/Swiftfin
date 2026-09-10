//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(macOS)
import AppKit
import Combine
import CoreData
import Foundation
import Pulse
import SwiftUI

// The shared layer uses UIKit names for image/color/device APIs. Keep those
// names scoped to the native Mac target instead of leaking AppKit through
// every portable file.
typealias UIImage = NSImage
typealias UIColor = NSColor
typealias UIFont = NSFont

extension NSColor {

    static var secondarySystemBackground: NSColor {
        controlBackgroundColor
    }

    static var tertiarySystemBackground: NSColor {
        underPageBackgroundColor
    }

    static var label: NSColor {
        labelColor
    }
}

extension NSImage {

    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
    }

    convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: .zero)
    }

    func pngData() -> Data? {
        guard let cgImage else { return nil }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        return bitmap.representation(using: .png, properties: [:])
    }

    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let cgImage else { return nil }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionQuality]
        )
    }
}

extension NSFont {

    static func preferredFont(forTextStyle style: NSFont.TextStyle) -> NSFont {
        switch style {
        case .largeTitle:
            .systemFont(ofSize: 34)
        case .title1:
            .systemFont(ofSize: 28)
        case .title2:
            .systemFont(ofSize: 22)
        case .title3:
            .systemFont(ofSize: 20)
        case .headline:
            .boldSystemFont(ofSize: 13)
        case .subheadline:
            .systemFont(ofSize: 12)
        case .callout:
            .systemFont(ofSize: 12)
        case .caption1:
            .systemFont(ofSize: 11)
        case .caption2:
            .systemFont(ofSize: 10)
        case .footnote:
            .systemFont(ofSize: 11)
        case .body:
            .systemFont(ofSize: 13)
        default:
            .systemFont(ofSize: NSFont.systemFontSize)
        }
    }

    static var familyNames: [String] {
        NSFontManager.shared.availableFontFamilies
    }

    var lineHeight: CGFloat {
        ascender - descender + leading
    }
}

enum UIBlurEffect {
    enum Style {
        case regular
    }
}

extension ToolbarItemPlacement {
    static var topBarLeading: Self {
        .navigation
    }

    static var topBarTrailing: Self {
        .automatic
    }

    static var navigationBarLeading: Self {
        .navigation
    }

    static var navigationBarTrailing: Self {
        .automatic
    }

    static var bottomBar: Self {
        .status
    }
}

final class UIDevice {

    static let current = UIDevice()

    let name: String = Host.current().localizedName ?? "Mac"
}

enum UINotificationFeedbackGenerator {
    enum FeedbackType {
        case error
        case success
        case warning
    }
}

enum UIImpactFeedbackGenerator {
    enum FeedbackStyle {
        case light
        case medium
        case heavy
        case soft
        case rigid
    }
}

final class UIApplication {

    static let shared = UIApplication()
    static let openSettingsURLString = "x-apple.systempreferences:"

    static var appVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    static var bundleVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }

    var keyWindow: NSWindow? {
        NSApp?.keyWindow
    }

    var alternateIconName: String? {
        nil
    }

    func setAppearance(_ appearance: NSAppearance.Name) {
        NSApp?.appearance = NSAppearance(named: appearance)
    }

    func canOpenURL(_ url: URL) -> Bool {
        NSWorkspace.shared.urlForApplication(toOpen: url) != nil
    }

    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    func open(_ url: URL, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(NSWorkspace.shared.open(url))
    }

    func open(_ url: URL) async -> Bool {
        NSWorkspace.shared.open(url)
    }

    func setAlternateIconName(_ name: String?) async throws {}
}

/// Observes and drives the state of the app's Mac window, which the
/// shared layer has no other way to reach.
@MainActor
final class MacWindowState: ObservableObject {

    static let shared = MacWindowState()

    @Published
    private(set) var isFullScreen: Bool
    @Published
    private(set) var isFloating: Bool = false

    private var frameBeforeFloating: NSRect?
    private var minSizeBeforeFloating: NSSize?

    private var cancellables: Set<AnyCancellable> = []
    private var isCursorHidden = false

    private var currentWindow: NSWindow? {
        NSApp?.keyWindow ?? NSApp?.mainWindow ?? NSApp?.windows.first
    }

    private init() {
        isFullScreen = NSApp?.keyWindow?.styleMask.contains(.fullScreen) ?? false

        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: NSWindow.didEnterFullScreenNotification)
                .map { _ in true },
            NotificationCenter.default
                .publisher(for: NSWindow.didExitFullScreenNotification)
                .map { _ in false }
        )
        .sink { [weak self] isFullScreen in
            Task { @MainActor in
                self?.isFullScreen = isFullScreen
            }
        }
        .store(in: &cancellables)
    }

    func toggleFullScreen() {
        currentWindow?.toggleFullScreen(nil)
    }

    /// Toggles a compact always-on-top player window.
    ///
    /// The VLC and MPV renderers draw into an `NSView`, not an
    /// `AVPlayerLayer` or a sample-buffer layer, so AVKit's system
    /// Picture in Picture cannot host them. A floating mini window is the
    /// equivalent macOS affordance and works for every backend.
    func toggleFloating() {
        guard let window = currentWindow else { return }

        if isFloating {
            isFloating = false
            window.level = .normal
            window.collectionBehavior.remove(.canJoinAllSpaces)

            if let minSizeBeforeFloating {
                window.contentMinSize = minSizeBeforeFloating
            }

            if let frameBeforeFloating {
                window.setFrame(frameBeforeFloating, display: true, animate: true)
            }

            minSizeBeforeFloating = nil
            frameBeforeFloating = nil
            return
        }

        if window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }

        frameBeforeFloating = window.frame
        minSizeBeforeFloating = window.contentMinSize

        // Publishing first lets the scene relax its browsing minimum, which
        // would otherwise clamp the mini window straight back up.
        isFloating = true
        window.contentMinSize = NSSize(width: 320, height: 180)
        window.level = .floating
        window.collectionBehavior.insert(.canJoinAllSpaces)

        let width: CGFloat = 480
        let size = NSSize(width: width, height: (width * 9 / 16).rounded())
        let visible = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let origin = NSPoint(
            x: visible.maxX - size.width - 24,
            y: visible.minY + 24
        )

        // SwiftUI applies the relaxed minimum on the next turn of the runloop.
        DispatchQueue.main.async {
            window.setFrame(NSRect(origin: origin, size: size), display: true, animate: true)
        }
    }

    /// Hides the pointer until the next mouse movement.
    ///
    /// Uses `setHiddenUntilMouseMoves` in both directions: AppKit un-hides
    /// on the next movement without telling us, so pairing it with
    /// `NSCursor.unhide()` would drive the hide count negative and leave the
    /// cursor permanently un-hideable.
    func setCursorHidden(_ hidden: Bool) {
        guard hidden != isCursorHidden else { return }
        isCursorHidden = hidden

        NSCursor.setHiddenUntilMouseMoves(hidden)
    }
}

extension View {
    @ViewBuilder
    func prefersStatusBarHidden(_ hidden: Bool = true) -> some View {
        self
    }
}

extension Image {
    init(uiImage: NSImage) {
        self.init(nsImage: uiImage)
    }
}

struct SplitLoginWindowView<Leading: View, Trailing: View>: View {

    private let isLoading: Bool
    private let leadingContentView: Leading
    private let trailingContentView: Trailing
    private let backgroundImageSource: ImageSource?

    init(
        isLoading: Bool = false,
        backgroundImageSource: ImageSource? = nil,
        @ViewBuilder leadingContentView: @escaping () -> Leading,
        @ViewBuilder trailingContentView: @escaping () -> Trailing
    ) {
        self.isLoading = isLoading
        self.backgroundImageSource = backgroundImageSource
        self.leadingContentView = leadingContentView()
        self.trailingContentView = trailingContentView()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            Form {
                leadingContentView
            }
            .formStyle(.grouped)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            Form {
                trailingContentView
            }
            .formStyle(.grouped)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 800, height: 500)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if isLoading {
                    ProgressView()
                }
            }
        }
        .background {
            if let backgroundImageSource {
                ZStack {
                    ImageView(backgroundImageSource)
                        .aspectRatio(contentMode: .fill)
                        .id(backgroundImageSource)
                        .transition(.opacity)
                        .animation(.linear, value: backgroundImageSource)

                    Color.black.opacity(0.9)
                }
                .ignoresSafeArea()
            }
        }
    }
}

struct MacConsoleView: View {

    let store: LoggerStore

    @FetchRequest
    private var messages: FetchedResults<LoggerMessageEntity>

    init(store: LoggerStore = .shared) {
        self.store = store

        let request = NSFetchRequest<LoggerMessageEntity>(entityName: "LoggerMessageEntity")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \LoggerMessageEntity.createdAt, ascending: false)
        ]
        request.predicate = NSPredicate(format: "task == nil")
        self._messages = FetchRequest(fetchRequest: request)
    }

    var body: some View {
        List {
            if messages.isEmpty {
                Text(L10n.none)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(messages, id: \.objectID) { message in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.text)
                        // developer log console: a file:line:timestamp stamp is
                        // diagnostic output, not localizable prose
                        // swiftlint:disable:next hard_coded_display_string
                        Text("\(message.file):\(message.line) · \(message.formattedTimestamp)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .environment(\.managedObjectContext, store.viewContext)
        .navigationTitle(L10n.logs)
    }
}

#endif
