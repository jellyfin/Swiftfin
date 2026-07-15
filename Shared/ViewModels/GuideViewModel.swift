//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

@MainActor
final class GuideViewModel: ViewModel {

    private static let pageSize = 20
    private static let viewModelLimit = 200

    let startDate: Date = GuideViewModel.currentHalfHour()
    let scrollProxy = GuideScrollProxy()

    @Published
    private(set) var now: Date = .now

    private var programsViewModels: [String: PagingLibraryViewModel<ChannelProgramsLibrary>] = [:]
    private var accessOrder: [String] = []

    override init() {
        super.init()

        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                Task { @MainActor in
                    self?.now = date
                }
            }
            .store(in: &cancellables)
    }

    func programsViewModel(for channel: BaseItemDto) -> PagingLibraryViewModel<ChannelProgramsLibrary> {
        let key = channel.id ?? channel.displayTitle

        if let existing = programsViewModels[key] {
            markAccessed(key)
            return existing
        }

        let viewModel = PagingLibraryViewModel(
            library: ChannelProgramsLibrary(channel: channel, startDate: startDate),
            pageSize: Self.pageSize
        )
        programsViewModels[key] = viewModel
        markAccessed(key)

        if accessOrder.count > Self.viewModelLimit, let oldest = accessOrder.first {
            accessOrder.removeFirst()
            programsViewModels[oldest] = nil
        }

        return viewModel
    }

    private func markAccessed(_ key: String) {
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }

        accessOrder.append(key)
    }

    private static func currentHalfHour() -> Date {
        let current = Date.now
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: current)
        let minute = calendar.component(.minute, from: current)

        return calendar.date(bySettingHour: hour, minute: minute - minute % 30, second: 0, of: current) ?? current
    }
}
