//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@MainActor
@Stateful
final class ServerBackupViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh
        case createBackup(options: BackupOptionsDto)
        case restore(backup: BackupManifestDto)

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.refreshing, then: .initial)
            case .createBackup:
                .background(.creating)
            case .restore:
                .background(.restoring)
            }
        }
    }

    enum BackgroundState {
        case creating
        case restoring
    }

    enum Event {
        case created
        case restored
    }

    enum State {
        case initial
        case error
        case refreshing
    }

    @Published
    private(set) var backups: [BackupManifestDto] = []

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let request = Paths.listBackups
        let response = try await send(request)

        backups = response.value.sorted { $0.dateCreated > $1.dateCreated }
    }

    @Function(\Action.Cases.createBackup)
    private func _createBackup(_ options: BackupOptionsDto) async throws {
        let request = Paths.createBackup(options)
        let response = try await send(request)

        backups = backups.prepending(response.value)

        events.send(.created)
    }

    @Function(\Action.Cases.restore)
    private func _restore(_ backup: BackupManifestDto) async throws {
        let archiveFileName = URL(fileURLWithPath: backup.path).lastPathComponent
        let parameters = BackupRestoreRequestDto(archiveFileName: archiveFileName)
        let request = Paths.startRestoreBackup(parameters)
        _ = try await send(request)

        events.send(.restored)
    }
}
