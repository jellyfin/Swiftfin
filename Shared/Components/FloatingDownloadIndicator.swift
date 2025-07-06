//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

// MARK: - CGPoint Codable Extension

extension CGPoint: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }

    private enum CodingKeys: String, CodingKey {
        case x
        case y
    }
}

/// A floating, draggable download progress indicator that shows active downloads
///
/// Features:
/// - Shows immediately when downloads start (including preparation phase)
/// - Real-time progress updates with animated progress ring
/// - Draggable across the screen with position persistence
/// - Haptic feedback for smooth user interaction
/// - Automatic visibility management
struct FloatingDownloadIndicator: View {

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    private var downloadManager: DownloadManager

    // Position state for draggable functionality
    @State
    private var currentPosition: CGPoint = .zero
    @State
    private var dragOffset: CGSize = .zero
    @State
    private var isDragging: Bool = false
    @State
    private var hasInitializedPosition: Bool = false

    init() {
        self.downloadManager = Container.shared.downloadManager()
    }

    // Get downloads that are currently in progress (including preparing to download)
    // This includes both .ready (preparing) and .downloading (active) states for immediate feedback
    private var activeDownloads: [DownloadTask] {
        downloadManager.downloads.filter { task in
            switch task.state {
            case .ready, .downloading:
                return true
            default:
                return false
            }
        }
    }

    // Check if indicator should be visible
    private var shouldShow: Bool {
        !activeDownloads.isEmpty
    }

    // Calculate overall progress across all active downloads
    private var overallProgress: Double {
        guard !activeDownloads.isEmpty else { return 0 }

        let totalProgress = activeDownloads.map { task -> Double in
            switch task.state {
            case let .downloading(progress):
                return progress
            case .ready:
                return 0.0 // Ready downloads haven't started yet
            default:
                return 0.0
            }
        }.reduce(0, +)

        return totalProgress / Double(activeDownloads.count)
    }

    // Get the count of active downloads
    private var downloadCount: Int {
        activeDownloads.count
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if shouldShow {
                    HStack(spacing: 8) {
                        // Download icon with progress ring
                        ZStack {
                            CircularProgressView(
                                progress: overallProgress,
                                size: 20,
                                strokeWidth: 2,
                                backgroundColor: Color.primary.opacity(0.2),
                                progressColor: accentColor,
                                animation: .linear(duration: 0.2)
                            )

                            // Add a subtle pulse animation for downloads that are preparing
                            if overallProgress == 0 {
                                Circle()
                                    .stroke(accentColor.opacity(0.3), lineWidth: 2)
                                    .frame(width: 20, height: 20)
                                    .scaleEffect(1.2)
                                    .opacity(0.6)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(), value: shouldShow)
                            }

                            // Download arrow icon
                            Image(systemName: "arrow.down")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(accentColor)
                        }

                        // Download count and percentage
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(downloadCount) download\(downloadCount == 1 ? "" : "s")")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Text("\(Int(overallProgress * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .scaleEffect(isDragging ? 1.1 : 1.0) // Slightly scale up when dragging
                    .opacity(isDragging ? 0.8 : 1.0) // Slightly fade when dragging
                    .position(
                        x: currentPosition.x + dragOffset.width,
                        y: currentPosition.y + dragOffset.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    // Haptic feedback when drag starts
                                    #if os(iOS)
                                    let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                                    impactGenerator.impactOccurred()
                                    #endif
                                }
                                isDragging = true
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                isDragging = false

                                // Calculate new position with bounds checking
                                let newX = max(50, min(geometry.size.width - 50, currentPosition.x + value.translation.width))
                                let newY = max(50, min(geometry.size.height - 50, currentPosition.y + value.translation.height))

                                currentPosition = CGPoint(x: newX, y: newY)
                                dragOffset = .zero

                                // Save position to UserDefaults
                                savePosition()

                                // Haptic feedback when drag ends
                                #if os(iOS)
                                let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                                impactGenerator.impactOccurred()
                                #endif
                            }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
                }
            }
            .onAppear {
                if !hasInitializedPosition {
                    initializePosition(in: geometry.size)
                    hasInitializedPosition = true
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: shouldShow)
        .allowsHitTesting(shouldShow) // Only allow interaction when visible
        .onTapGesture {
            if !isDragging {
                // Optional: Navigate to download list when tapped
                // Could be implemented later if desired
            }
        }
    }

    // MARK: - Helper Methods

    private func initializePosition(in size: CGSize) {
        // Try to load saved position first
        if let savedData = UserDefaults.standard.data(forKey: "FloatingDownloadIndicatorPosition"),
           let savedPosition = try? JSONDecoder().decode(CGPoint.self, from: savedData)
        {
            // Validate saved position is still within bounds
            let validX = max(50, min(size.width - 50, savedPosition.x))
            let validY = max(50, min(size.height - 50, savedPosition.y))
            currentPosition = CGPoint(x: validX, y: validY)
        } else {
            // Set default position (top-right corner with some padding)
            currentPosition = CGPoint(x: size.width - 100, y: 100)
        }
    }

    private func savePosition() {
        if let encoded = try? JSONEncoder().encode(currentPosition) {
            UserDefaults.standard.set(encoded, forKey: "FloatingDownloadIndicatorPosition")
        }
    }
}

// MARK: - Preview

struct FloatingDownloadIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()

            VStack {
                Spacer()
                Text("Main Content")
                Spacer()
            }

            VStack {
                HStack {
                    Spacer()
                    FloatingDownloadIndicator()
                }
                .padding()
                Spacer()
            }
        }
    }
}
