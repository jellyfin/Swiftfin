//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension BaseItemDto {

    func posterAccessibility(configuration: PosterConfiguration) -> PosterAccessibility {
        let playbackItem = currentProgram ?? self
        var details = [posterAccessibilitySubtitle(using: configuration.subtitleField)]

        if let runtime = playbackItem.runtime {
            details.append(L10n.posterAccessibilityRuntime(PosterAccessibility.duration(runtime)))
        }

        details.append(contentsOf: playbackItem.posterAccessibilityPlaybackState)

        if isRecording {
            details.append(L10n.recording)
        }

        if userData?.isFavorite == true {
            details.append(L10n.favorited)
        }

        return PosterAccessibility(
            label: PosterAccessibility
                .joined(posterAccessibilityTitleComponents + (currentProgram?.posterAccessibilityTitleComponents ?? [])),
            value: PosterAccessibility.joined(details)
        )
    }

    private var posterAccessibilityTitleComponents: [String?] {
        var components: [String?] = []

        if type == .episode || type == .season {
            components.append(seriesName)

            let seasonNumber = type == .season ? indexNumber : parentIndexNumber
            if let seasonNumber {
                components.append(L10n.posterAccessibilitySeason(seasonNumber.formatted()))
            }

            if type == .episode, let indexNumber {
                let number = if let indexNumberEnd, indexNumberEnd > indexNumber {
                    L10n.posterAccessibilityEpisodeRange(indexNumber.formatted(), indexNumberEnd.formatted())
                } else {
                    L10n.episodeNumber(indexNumber.formatted())
                }
                components.append(number)
            }
        }

        components.append(displayTitle)

        if type == .person {
            components.append(subtitle)
        }

        if isPosterAccessibilityProgram {
            components.append(channelName)
            if let startDate {
                components.append(L10n.posterAccessibilityStartTime(startDate.formatted(date: .abbreviated, time: .shortened)))
            }
            if let endDate {
                components.append(L10n.posterAccessibilityEndTime(endDate.formatted(date: .abbreviated, time: .shortened)))
            }
        }

        return components
    }

    private func posterAccessibilitySubtitle(using field: PosterSubtitleField) -> String? {
        guard type != .person, let subtitle = posterSubtitle(using: field) else { return nil }

        if extraType != nil {
            return subtitle
        }

        switch field {
        case .none, .runtime:
            // Runtime is always spoken, even with visual labels hidden.
            return nil
        case .communityRating:
            guard let communityRating else { return nil }
            return L10n.posterAccessibilityCommunityRating(communityRating.formatted(.number.precision(.fractionLength(0 ... 1))))
        case .criticRating:
            guard let criticRating else { return nil }
            let rating = (criticRating / 100).formatted(.percent.precision(.fractionLength(0)))
            return L10n.posterAccessibilityDetail(field.displayTitle, rating)
        default:
            return L10n.posterAccessibilityDetail(field.displayTitle, subtitle)
        }
    }

    private var isPosterAccessibilityProgram: Bool {
        type == .program || type == .liveTvProgram || type == .tvProgram
    }

    private var posterAccessibilityPlaybackState: [String?] {
        if isPosterAccessibilityProgram || isLiveStream || type == .tvChannel || type == .liveTvChannel {
            if isAiring, let startDate, let endDate, endDate > startDate {
                let now = Date.now
                let remaining = Duration.seconds(max(0, endDate.timeIntervalSince(now)))
                return [
                    L10n.live,
                    L10n.posterAccessibilityRemaining(PosterAccessibility.duration(remaining))
                ]
            }
            if isUnaired {
                return [L10n.unaired]
            }
            if hasAired {
                return [L10n.ended]
            }
            return [isLiveStream ? L10n.live : nil]
        }

        if isUnaired {
            return [L10n.unaired]
        }
        if isMissing {
            return [L10n.missing]
        }
        guard canBePlayed else { return [] }

        var state: [String?] = []
        let position = max(0, userData?.playbackPositionTicks ?? 0)
        let percentage = userData?.playedPercentage ?? 0
        let hasProgress = position > 0 || (userData?.isPlayed != true && percentage.isFinite && percentage > 0)

        if hasProgress {
            state.append(userData?.isPlayed == true ? L10n.rewatching : L10n.inProgress)

            if let runTimeTicks, runTimeTicks > 0, position > 0 {
                let remaining = Duration.ticks(max(0, runTimeTicks - position))
                state.append(L10n.posterAccessibilityRemaining(PosterAccessibility.duration(remaining)))
            }
        } else if let isPlayed = userData?.isPlayed {
            state.append(isPlayed ? L10n.played : L10n.unplayed)
        }

        if let count = userData?.unplayedItemCount, count > 0, userData?.isPlayed != true {
            state.append(L10n.posterAccessibilityUnplayedCount(count.formatted()))
        }

        return state
    }
}
