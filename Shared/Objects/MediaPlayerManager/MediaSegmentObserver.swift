//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI

/// Observes playback seconds against an item's media segments,
/// performing automatic skips and publishing the segment that
/// should currently offer a skip action.
extension MediaPlayerManager {

    var segmentObserver: MediaSegmentObserver? {
        playbackItem?.observers
            .first(where: { $0 is MediaSegmentObserver }) as? MediaSegmentObserver
    }
}

class MediaSegmentObserver: ViewModel, MediaPlayerObserver {

    /// The maximum duration that a skip button should be presented
    /// standalone, without the rest of the playback overlay.
    static let standalonePresentationDuration: Duration = .seconds(8)

    /// The maximum difference between consecutive seconds for a
    /// segment entry to be considered from natural playback
    /// instead of from a seek.
    private static let naturalEntryThreshold: Duration = .seconds(5)

    /// The segment that the current playback seconds is within,
    /// if a skip action should be offered for it.
    @Published
    private(set) var currentSegment: MediaSegmentDto?

    /// Whether the skip button for the current segment should be
    /// presented standalone, without the rest of the playback overlay.
    @Published
    private(set) var isStandalonePresentation: Bool = false

    /// Whether the current segment was entered by natural playback
    /// instead of by seeking into it. Useful for deciding initial
    /// focus of a skip button.
    private(set) var enteredCurrentSegmentNaturally: Bool = false

    /// Segments that were already automatically skipped, or were
    /// entered by seeking, and should only offer a button instead
    /// of automatically skipping again.
    private var autoSkipSpentSegmentIDs: Set<String> = []
    private var lastSeconds: Duration?
    private var segments: [MediaSegmentDto] = []
    private var standalonePresentationTask: Task<Void, Never>?

    weak var manager: MediaPlayerManager? {
        didSet {
            if let manager {
                setup(with: manager)
            }
        }
    }

    init(item: MediaPlayerItem) {
        super.init()

        guard let itemID = item.baseItem.id else { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                let request = Paths.getItemSegments(itemID: itemID)
                let response = try await userSession.client.send(request)
                let segments = response.value.items ?? []

                let segmentDescriptions = segments
                    .map { "\($0.type?.rawValue ?? "Unknown") \($0.startSeconds ?? .zero)-\($0.endSeconds ?? .zero)" }
                    .joined(separator: ", ")

                logger.debug("[MediaSegments] fetched \(segments.count) segment(s) for item \(itemID): \(segmentDescriptions)")

                await MainActor.run {
                    self.segments = segments
                }
            } catch {
                logger.error("[MediaSegments] failed fetching segments for item \(itemID): \(error)")
            }
        }
    }

    private func setup(with manager: MediaPlayerManager) {
        cancellables = []

        manager.secondsBox.$value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.secondsDidChange($0) }
            .store(in: &cancellables)
    }

    // MARK: - seconds

    private func behavior(for segment: MediaSegmentDto) -> MediaSegmentBehavior {
        guard Defaults[.VideoPlayer.enableMediaSegments], let type = segment.type else { return .off }
        return Defaults[.VideoPlayer.mediaSegmentBehaviors][type] ?? .off
    }

    private func secondsDidChange(_ newSeconds: Duration) {
        // Don't observe seconds until segments are loaded so that
        // the first observed seconds correctly determines natural
        // entry for segments at the start of an item.
        guard segments.isNotEmpty else { return }
        defer { lastSeconds = newSeconds }

        let activeSegment = segments.first { segment in
            guard let start = segment.startSeconds, let end = segment.endSeconds else { return false }
            return (start ..< end).contains(newSeconds) && behavior(for: segment) != .off
        }

        guard let activeSegment, let segmentID = activeSegment.id else {
            if currentSegment != nil {
                logger.debug("[MediaSegments] exited segment")
                setCurrentSegment(nil)
            }
            return
        }

        if behavior(for: activeSegment) == .skip, !autoSkipSpentSegmentIDs.contains(segmentID) {
            autoSkipSpentSegmentIDs.insert(segmentID)

            if isNaturalEntry(into: activeSegment, at: newSeconds) {
                logger.debug("[MediaSegments] automatically skipping \(activeSegment.type?.rawValue ?? "Unknown") segment")
                skip(segment: activeSegment)
                return
            } else {
                logger.debug("[MediaSegments] entered skip segment by seeking, offering button instead")
            }
        }

        if activeSegment != currentSegment {
            logger.debug("[MediaSegments] presenting skip button for \(activeSegment.type?.rawValue ?? "Unknown") segment")
            enteredCurrentSegmentNaturally = isNaturalEntry(into: activeSegment, at: newSeconds)
            setCurrentSegment(activeSegment)
        }
    }

    /// Whether the given seconds entered the segment from natural
    /// playback: crossing the segment start with a small difference
    /// from the last observed seconds, instead of seeking into it.
    private func isNaturalEntry(into segment: MediaSegmentDto, at seconds: Duration) -> Bool {
        guard let start = segment.startSeconds else { return false }

        guard let lastSeconds else {
            // First observed seconds, like playback starting
            // within a segment at the start of an item.
            return seconds - start <= Self.naturalEntryThreshold
        }

        // `<=` so that a segment starting at zero is naturally
        // entered by the first ticks of playback.
        guard lastSeconds <= start else { return false }
        return seconds - lastSeconds <= Self.naturalEntryThreshold
    }

    // MARK: - skipping

    func skipCurrentSegment() {
        guard let currentSegment else { return }
        skip(segment: currentSegment)
    }

    private func skip(segment: MediaSegmentDto) {
        guard let end = segment.endSeconds, let manager else { return }

        if let segmentID = segment.id {
            autoSkipSpentSegmentIDs.insert(segmentID)
        }

        logger.debug("[MediaSegments] skipping to \(end)")

        setCurrentSegment(nil)
        manager.seconds = end
        manager.proxy?.setSeconds(end)
    }

    // MARK: - presentation

    private func setCurrentSegment(_ segment: MediaSegmentDto?) {
        standalonePresentationTask?.cancel()
        currentSegment = segment

        guard let segment, let end = segment.endSeconds else {
            isStandalonePresentation = false
            return
        }

        isStandalonePresentation = true

        let remaining = end - (manager?.seconds ?? .zero)
        let window = min(Self.standalonePresentationDuration, remaining)

        standalonePresentationTask = Task { [weak self] in
            try? await Task.sleep(for: window)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.isStandalonePresentation = false
            }
        }
    }
}
