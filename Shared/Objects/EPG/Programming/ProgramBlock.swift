//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct ProgramBlock: Identifiable {

    struct ID: Hashable {

        let channelID: String?
        let programIDs: [String?]
        let start: Date
        let end: Date
    }

    let id: ID
    let programs: [BaseItemDto]
    let start: Date
    let end: Date

    var isGroup: Bool {
        programs.count > 1
    }

    init(
        programs: [BaseItemDto],
        start: Date,
        end: Date
    ) {
        self.id = ID(
            channelID: programs.first?.channelID,
            programIDs: programs.map(\.id),
            start: start,
            end: end
        )
        self.programs = programs
        self.start = start
        self.end = end
    }

    func isAiring(at date: Date) -> Bool {
        programs.contains { program in
            guard let start = program.startDate, let end = program.endDate else { return false }
            return start <= date && date < end
        }
    }
}

extension Collection<BaseItemDto> {

    func programBlocks(
        startDate: Date,
        endDate: Date
    ) -> [ProgramBlock] {
        let clampedPrograms = compactMap { ClampedProgram($0, clampedTo: startDate ... endDate) }
            .sorted { $0.start < $1.start }

        var chunks: [[ClampedProgram]] = []
        var currentChunk: [ClampedProgram] = []
        var currentEnd: Date?

        for program in clampedPrograms {
            let joinsCurrentChunk = program.isShort &&
                currentChunk.first?.isShort == true &&
                currentEnd.map { program.start <= $0 } == true

            if currentChunk.isNotEmpty, !joinsCurrentChunk {
                chunks.append(currentChunk)
                currentChunk.removeAll(keepingCapacity: true)
                currentEnd = nil
            }

            currentChunk.append(program)
            if let previousEnd = currentEnd {
                currentEnd = previousEnd > program.end ? previousEnd : program.end
            } else {
                currentEnd = program.end
            }
        }

        if currentChunk.isNotEmpty {
            chunks.append(currentChunk)
        }

        return chunks.compactMap { chunk in
            guard let first = chunk.first,
                  let end = chunk.map(\.end).max()
            else { return nil }

            return ProgramBlock(
                programs: chunk.map(\.program),
                start: first.start,
                end: end
            )
        }
    }
}
