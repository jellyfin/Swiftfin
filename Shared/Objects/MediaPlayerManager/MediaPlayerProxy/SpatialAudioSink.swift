//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Logging
import MPVUI
import SpatialAudioBridge
import SpatialAudioPlayback
import Synchronization

/// Plays mpv's TrueHD Atmos and DTS:X passthrough as spatial audio, on the synchronizer mpv keeps its clock on.
/// Other TrueHD and DTS tracks fall back to mpv's PCM.
@available(iOS 26, tvOS 26, *)
final class SpatialAudioSink: MPVPassthroughAudioSink {

    private let logger = Logger.swiftfin()
    private let state = Mutex(State())

    private struct State {
        var renderer: SpatialAudioRenderer?
        var activator: AtmosOutputActivator?
        var fallback: (@Sendable () -> Void)?
        var timeline: Timeline?
        var generation = 0
        var readyGeneration = -1
        var volume: Float = 1
    }

    private struct Timeline {
        let bursts: AsyncStream<Data>.Continuation
        let feeder: Task<Void, Never>
    }

    var isReady: Bool {
        state.withLock { $0.readyGeneration == $0.generation }
    }

    func open(
        codec: MPVPassthroughAudioCodec,
        synchronizer: AVSampleBufferRenderSynchronizer,
        fallback: @escaping @Sendable () -> Void
    ) -> Bool {
        let codec: SpatialAudioCodec = codec == .trueHD ? .trueHDAtmos : .dtsX
        let renderer: SpatialAudioRenderer
        do {
            renderer = try SpatialAudioRenderer(codec: codec, synchronizer: synchronizer)
        } catch {
            logger.warning("Unable to play \(codec) as spatial audio: \(error)")
            return false
        }

        state.withLock { state in
            state.renderer = renderer
            state.fallback = fallback
        }
        applyLatestVolume(to: renderer)

        // Switches the receiver to Atmos while the synchronizer runs
        Task { @MainActor in
            let activator = AtmosOutputActivator()
            activator.attach(to: synchronizer)

            // mpv may have closed this output already
            let isCurrent = state.withLock { state in
                guard state.renderer === renderer else { return false }

                state.activator = activator
                return true
            }
            if !isCurrent {
                activator.detach()
            }
        }

        let outputs = AVAudioSession.sharedInstance()
            .currentRoute
            .outputs
            .map { "\($0.portType.rawValue) (spatial audio: \($0.isSpatialAudioEnabled))" }
        logger.info("Playing \(codec) as spatial audio on \(outputs.joined(separator: ", "))")
        return true
    }

    /// Replaces the previous timeline, after a seek or reset.
    func begin(at time: CMTime) {
        let (bursts, input) = AsyncStream<Data>.makeStream()
        state.withLock { state in
            state.generation += 1
            let generation = state.generation
            let previous = state.timeline
            previous?.bursts.finish()
            previous?.feeder.cancel()
            guard let renderer = state.renderer else { return }

            let feeder = Task {
                await feed(bursts, into: renderer, from: time, after: previous?.feeder, generation: generation)
            }
            state.timeline = Timeline(bursts: input, feeder: feeder)
        }
    }

    func write(_ bursts: UnsafeRawBufferPointer) {
        let data = Data(bursts)
        _ = state.withLock { $0.timeline }?.bursts.yield(data)
    }

    /// The feeder then flushes what the renderer holds back.
    func end() {
        state.withLock { $0.timeline }?.bursts.finish()
    }

    func close() {
        let (timeline, renderer, activator) = state.withLock { state in
            defer {
                // A new generation, so a late feeder cannot touch the next session
                state = State(generation: state.generation + 1, volume: state.volume)
            }
            return (state.timeline, state.renderer, state.activator)
        }
        timeline?.bursts.finish()
        timeline?.feeder.cancel()

        // Releases an enqueue the feeder may still wait in
        if let renderer {
            Task { try? await renderer.begin(at: .zero) }
        }
        if let activator {
            Task { @MainActor in activator.detach() }
        }
    }

    func setVolume(_ volume: Float) {
        guard let renderer = state.withLock({ state in
            state.volume = volume
            return state.renderer
        }) else { return }

        applyLatestVolume(to: renderer)
    }

    /// Tasks can reach the renderer out of order, so each ends on the latest volume.
    private func applyLatestVolume(to renderer: SpatialAudioRenderer) {
        Task {
            var applied: Float
            repeat {
                applied = latestVolume
                await renderer.setVolume(applied)
            } while applied != latestVolume
        }
    }

    private var latestVolume: Float {
        state.withLock { $0.volume }
    }

    // MARK: - Feeding the renderer

    private func feed(
        _ bursts: AsyncStream<Data>,
        into renderer: SpatialAudioRenderer,
        from time: CMTime,
        after previous: Task<Void, Never>?,
        generation: Int
    ) async {
        do {
            // Releases the previous feeder, then drops what it queued before stopping
            try await renderer.begin(at: time)
            await previous?.value
            try await renderer.begin(at: time)

            var unpacker = IEC61937Unpacker()
            var enqueued = false
            var ready = false
            for await chunk in bursts {
                let stream = try unpacker.unpack(chunk)
                guard !stream.isEmpty else { continue }

                // mpv's clock counts the TrueHD units the unpacker drops before the first major sync
                try await renderer.enqueue(stream, time: time + unpacker.skippedDuration)
                enqueued = true

                if !ready, await renderer.isReadyToPlay {
                    ready = true
                    markReady(generation)
                }
            }

            // The renderer holds back up to 1.5 s until flushed
            guard !Task.isCancelled else { return }

            if enqueued {
                do {
                    try unpacker.finish()
                } catch {
                    logger.warning("Spatial audio ended mid-unit: \(error)")
                }
                try await renderer.endOfStream()
            }

            // Also with nothing to play, so mpv's clock reaches the end
            markReady(generation)
        } catch is CancellationError {
        } catch {
            let fallback = state.withLock { state in
                state.generation == generation ? state.fallback : nil
            }
            if let fallback {
                logger.warning("Playing mpv's audio instead of spatial audio: \(error)")
                fallback()
            }
        }
    }

    private func markReady(_ generation: Int) {
        state.withLock { state in
            if state.generation == generation {
                state.readyGeneration = generation
            }
        }
    }
}
